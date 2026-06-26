# Sesión 2: Cambio de usuario SSH a bddadmin + Exportación a OVA

## Fecha
2026-06-25

## Resumen
- Cambio del usuario SSH de `vagrant` a `bddadmin`/`bddadmin`
- Corrección definitiva del bug de sincronización GTID en `provision-role.sh`
- Reparación manual de bdd-nodo03
- Exportación de los 3 nodos como OVA para usar en VirtualBox sin Vagrant

---

## 1. Cambio de usuario SSH: vagrant → bddadmin

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `Vagrantfile` | `config.ssh.username` dinámico: `bddadmin` si la VM existe, `vagrant` si es primera vez |
| `scripts/provision-base.sh` | Creación de `bddadmin` con password `bddadmin`, sudo NOPASSWD, copia de claves SSH, habilitación de PasswordAuthentication |
| `scripts/create-bddadmin.sh` | Script auxiliar para crear `bddadmin` en VMs ya existentes |

### Detalle técnico

**Vagrantfile** — línea 15:
```ruby
config.ssh.username = Dir.glob(".vagrant/machines/*/virtualbox/id").any? ? "bddadmin" : "vagrant"
```

- **Primera vez** (`vagrant up` desde cero): no existe `.vagrant/machines/*/virtualbox/id` → usa `vagrant`, el provisioner `provision-base.sh` crea `bddadmin`, luego `.vagrant/` se genera, y en adelante Vagrant usa `bddadmin`.
- **VMs existentes**: detecta los `.id` files → usa `bddadmin`.

**provision-base.sh** — crea el usuario al inicio del provisionamiento base:
```bash
id -u bddadmin &>/dev/null || useradd -m -s /bin/bash -G sudo bddadmin
echo "bddadmin:bddadmin" | chpasswd
cp /home/vagrant/.ssh/authorized_keys /home/bddadmin/.ssh/
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "bddadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bddadmin
```

### Ejecución manual para VMs existentes

```bash
sudo bash /vagrant/scripts/create-bddadmin.sh
```

(Ejecutado en bdd-nodo01, bdd-nodo02, bdd-nodo03)

### Notas
- En Ubuntu 24.04 el servicio SSH es `ssh.service`, no `sshd.service`
- `config.ssh.insert_key = false` + `config.ssh.password` no funciona con `vagrant ssh -c` (requiere key-based auth). Se mantiene `insert_key = false` y se copian las claves de `vagrant` a `bddadmin`.

---

## 2. Corrección definitiva del bug GTID en provision-role.sh

### Historial del bug

| Versión | Enfoque | Problema |
|---------|---------|---------|
| Original | Ejecutar mismos SQL en todos los nodos | `Duplicate entry 1062` |
| Fix v1 | `mysqldump --databases --gtid` + `grep` para extraer GTID | `--gtid` con `--databases` NO produce la línea `SET GLOBAL gtid_slave_pos` → grep devuelve vacío → GTID nunca se establece |
| **Fix v2 (actual)** | `FLUSH TABLES WITH READ LOCK` + consulta directa `@@gtid_current_pos` | Correcto, independiente del formato del dump |

### Código final (provision-role.sh líneas 154-177)

```bash
# Lock maestro + obtener GTID + dump (atómico, consistente)
mysql -h "$MASTER_IP" -e "FLUSH TABLES WITH READ LOCK"
MASTER_GTID=$(mysql -h "$MASTER_IP" -NBe "SELECT @@gtid_current_pos")
mysqldump -h "$MASTER_IP" --databases lab_bdd --routines --triggers > /tmp/sync.sql
mysql -h "$MASTER_IP" -e "UNLOCK TABLES"

# Restaurar en esclavo
mysql < /tmp/sync.sql

# Establecer GTID para que el slave salte transacciones ya aplicadas
mysql -e "SET GLOBAL gtid_slave_pos='$MASTER_GTID'"
```

### También se agregó

```bash
set +H   # línea 2 de provision-role.sh
```

Para evitar history expansion de bash con el carácter `!` en las contraseñas (ej: `LabAdmin_2025!`).

---

## 3. Reparación manual de bdd-nodo03

bdd-nodo03 quedó con `Slave_SQL_Running: No` por `Duplicate entry` al haber restaurado datos con un GTID incorrecto.

### Pasos de reparación

```bash
# 1. Detener replicación y resetear
STOP SLAVE;
RESET SLAVE ALL;

# 2. Eliminar datos locales
DROP DATABASE IF EXISTS lab_bdd;

# 3. Hacer dump completo del maestro (con --all-databases --gtid)
mysqldump --all-databases --gtid --single-transaction > /vagrant/nodo03_full.sql

# 4. Restaurar en nodo03
mysql < /vagrant/nodo03_full.sql

# 5. Configurar GTID y replicación
SET GLOBAL gtid_slave_pos = '1-1-28';
CHANGE MASTER TO MASTER_HOST='192.168.56.101',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='ReplUser_2025!',
  MASTER_USE_GTID=slave_pos;
START SLAVE;
```

### Verificación

```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
Gtid_IO_Pos: 1-1-28
```

Snapshot: `fase10-completa-nodo03-fixed`

---

## 4. Exportación a OVA (VirtualBox standalone)

### Archivos generados

| Archivo | Tamaño | Descripción |
|---------|--------|-------------|
| `exports/bdd-nodo01.ova` | 785 MB | Maestro replicación física |
| `exports/bdd-nodo02.ova` | 766 MB | Esclavo replicación física |
| `exports/bdd-nodo03.ova` | 773 MB | Multimaster replicación lógica |
| `exports/IMPORTAR-EN-VIRTUALBOX.md` | — | Instrucciones de importación |

### Preparación previa

```bash
# 1. Limpiar VMs internamente
vagrant ssh <vm> -c "sudo bash -c '
  apt-get clean -qq
  journalctl --vacuum-time=1s
  rm -rf /var/log/*.gz /var/log/*.old
  > /var/log/mysql/mariadb.err
'"

# 2. Apagar VMs
vagrant halt <vm>

# 3. Eliminar carpeta compartida de Vagrant
VBoxManage sharedfolder remove <vm> --name "vagrant"

# 4. Exportar
VBoxManage export <vm> -o exports/<vm>.ova --ovf10 --options=manifest
```

### Las VMs exportadas incluyen

- MariaDB 10.x con replicación GTID ya configurada y sincronizada
- Usuario `bddadmin`/`bddadmin` con sudo NOPASSWD
- Red Host-Only `192.168.56.0/24`
- Sin dependencia de Vagrant (se eliminó la carpeta compartida)

### En la computadora destino (solo VirtualBox)

1. Importar los 3 `.ova` (Archivo → Importar servicio virtualizado)
2. Crear red Host-Only: `192.168.56.1 / 255.255.255.0`, DHCP deshabilitado
3. Iniciar VMs (orden: nodo01 → nodo02 → nodo03)
4. SSH: `bddadmin`/`bddadmin`
5. MariaDB: `root`/`LabAdmin_2025!`

---

## 5. Archivos modificados/creados en esta sesión

| Archivo | Acción | Propósito |
|---------|--------|-----------|
| `Vagrantfile` | Modificado | SSH username dinámico: bddadmin/vagrant |
| `scripts/provision-base.sh` | Modificado | Creación de usuario bddadmin |
| `scripts/provision-role.sh` | Modificado | Fix GTID v2 (FTWRL + consulta directa), `set +H` |
| `scripts/create-bddadmin.sh` | Creado | Script auxiliar para crear bddadmin en VMs existentes |
| `sql/fix-nodo03-v2.sql` | Creado | SQL de reparación para nodo03 (no usado, se hizo manual) |
| `sql/fix-nodo03-gtid.sql` | Creado | SQL para establecer GTID en nodo03 |
| `sql/check-counts.sql` | Creado | Query de verificación de consistencia |
| `exports/bdd-nodo01.ova` | Creado | VM exportada |
| `exports/bdd-nodo02.ova` | Creado | VM exportada |
| `exports/bdd-nodo03.ova` | Creado | VM exportada |
| `exports/IMPORTAR-EN-VIRTUALBOX.md` | Creado | Instrucciones de importación |
| `docs/04-fix-provision-role-bug.md` | Modificado | Actualizado con fix v2 |
| `docs/05-sesion2-bddadmin-y-exportacion.md` | Creado | Este documento |

---

## 6. Estado final

| Nodo | IP | Rol | GTID | Estado |
|------|----|-----|------|--------|
| bdd-nodo01 | 192.168.56.101 | Master | 1-1-28 | OK |
| bdd-nodo02 | 192.168.56.102 | Slave | 1-1-28 | OK, replicando |
| bdd-nodo03 | 192.168.56.103 | Multimaster | 1-3-180 | OK, replicando |

Datos consistentes en los 3 nodos:
- clientes: 21
- pedidos: 20
- detalle_pedidos: 34
- productos: 10
