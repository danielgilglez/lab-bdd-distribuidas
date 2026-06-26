# Fase 10 — Replicación Física Maestro-Esclavo

## Documentación de comandos manuales

---

## 1. Inicio del laboratorio

```powershell
# Desde PowerShell, ubicarse en la carpeta del laboratorio
cd C:\Users\Daniel Gil\Downloads\Fase\lab-bdd-vagrant

# Levantar nodo01 SIN provisionar (solo arrancar la VM)
vagrant up bdd-nodo01 --no-provision
```

### Problema inicial — VM colgada en SSH

El primer `vagrant up` se quedó atorado en `Waiting for machine to boot...` con el mensaje `SSH auth method: private key`. El proceso quedó con un lock stale.

**Solución:**

```powershell
# 1. Ver procesos colgados
Get-Process | Where-Object { $_.ProcessName -match "ruby|vagrant" }

# 2. Matar procesos colgados
Stop-Process -Id 10260, 10264 -Force

# 3. Forzar apagado de la VM desde VirtualBox directamente
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "bdd-nodo01" poweroff

# 4. Volver a levantar (asigna puerto alterno 2200)
vagrant up bdd-nodo01 --no-provision
```

---

## 2. Provisionar nodo01 como maestro

```powershell
# Ejecuta provision-base.sh + provision-role.sh (rol=master)
vagrant provision bdd-nodo01
```

**Lo que hace el provision:**
1. `apt-get install mariadb-server, mariadb-client`
2. Configura charset `utf8mb4`
3. Habilita `bind-address = 0.0.0.0`
4. Cambia contraseña root a `LabAdmin_2025!`
5. Configura `server_id = 1`, `log_bin`, `binlog_format = ROW`, `gtid_domain_id = 1`
6. Ejecuta scripts SQL (`01-schema.sql`, `02-data.sql`, `03-users.sql`)
7. Crea usuario `repl_user` con permisos `REPLICATION SLAVE`

### Verificar estado del maestro

```powershell
vagrant ssh bdd-nodo01 --command "mysql -u root -pLabAdmin_2025! -e 'SHOW MASTER STATUS\G'"
```

Salida esperada:
```
File: mariadb-bin.000001
Position: 18501
Binlog_Do_DB:
Binlog_Ignore_DB:
```

---

## 3. Levantar y provisionar nodo02 como esclavo

```powershell
# Levantar nodo02 (se provisiona automáticamente como slave)
vagrant up bdd-nodo02
```

### Problema — Error Duplicate Entry (1062)

El esclavo ejecutó los mismos scripts SQL (`01-schema.sql`, `02-data.sql`) que el maestro, por lo que al iniciar la replicación intentó insertar los mismos registros otra vez.

```
Slave_IO_Running: Yes
Slave_SQL_Running: No
Last_Error: Duplicate entry '1' for key 'PRIMARY'
```

**Solución completa:**

```sql
-- Paso 1: Detener replicación en el esclavo
STOP SLAVE;
RESET SLAVE ALL;

-- Paso 2: Eliminar datos duplicados
DROP DATABASE IF EXISTS lab_bdd;
```

```powershell
# Paso 3: Generar dump del maestro con GTID y posición exacta
vagrant ssh bdd-nodo01 --command "mysqldump -u root -pLabAdmin_2025! --all-databases --triggers --routines --events --flush-logs --master-data=2 --gtid > /tmp/master_dump.sql"

# Paso 4: Copiar dump al folder compartido
vagrant ssh bdd-nodo01 --command "cp /tmp/master_dump.sql /vagrant/"

# Paso 5: Restaurar dump en el esclavo
vagrant ssh bdd-nodo02 --command "mysql -u root -pLabAdmin_2025! < /vagrant/master_dump.sql"
```

```bash
# Paso 6: Obtener GTID del dump (dentro de bdd-nodo01)
grep "SET GLOBAL gtid_slave_pos" /vagrant/master_dump.sql
# Resultado: SET GLOBAL gtid_slave_pos='1-1-24';
```

```sql
-- Paso 7: Configurar replicación con GTID (ejecutar DENTRO del esclavo)
SET GLOBAL gtid_slave_pos = '1-1-24';
CHANGE MASTER TO
  MASTER_HOST = '192.168.56.101',
  MASTER_PORT = 3306,
  MASTER_USER = 'repl_user',
  MASTER_PASSWORD = 'ReplUser_2025!',
  MASTER_USE_GTID = slave_pos;
START SLAVE;
```

```bash
# O en un solo comando desde bash dentro de la VM:
set +H  # Desactiva history expansion de bash (para evitar error con !)
mysql -u root -pLabAdmin_2025! -e "STOP SLAVE; RESET SLAVE ALL; SET GLOBAL gtid_slave_pos='1-1-24'; CHANGE MASTER TO MASTER_HOST='192.168.56.101', MASTER_PORT=3306, MASTER_USER='repl_user', MASTER_PASSWORD='ReplUser_2025!', MASTER_USE_GTID=slave_pos; START SLAVE;"
```

### Verificar estado de la replicación

```bash
# Dentro del esclavo
mysql -u root -pLabAdmin_2025! -e "SHOW SLAVE STATUS\G" | grep -E "Running|Error|Behind"

# Desde PowerShell
vagrant ssh bdd-nodo02 --command "mysql -u root -pLabAdmin_2025! -e 'SHOW SLAVE STATUS\G'" | Select-String "Slave_IO_Running|Slave_SQL_Running|Last_Error|Seconds_Behind"
```

Salida esperada:
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Last_Error:
Seconds_Behind_Master: 0
```

---

## 4. Prueba de replicación en tiempo real

```bash
# Insertar registro en el MAESTRO (dentro de bdd-nodo01)
mysql -u root -pLabAdmin_2025! -e "INSERT INTO lab_bdd.clientes (nombre, apellido, email, region) VALUES ('TestFinal', 'ApellidoTest', 'test@final.com', 'norte');"
```

```bash
# Verificar en el MAESTRO
mysql -u root -pLabAdmin_2025! -e "SELECT COUNT(*) FROM lab_bdd.clientes;"

# Verificar en el ESCLAVO
mysql -u root -pLabAdmin_2025! -e "SELECT COUNT(*) FROM lab_bdd.clientes;"
```

Ambos deben mostrar `21` registros.

---

## 5. Problemas comunes con PowerShell quoting

PowerShell tiene problemas con ciertos caracteres en comandos `vagrant ssh`:
- **Paréntesis** `()` — los interpreta como invocación de función
- **Signo de exclamación** `!` — conflicta con el history expansion de bash
- **Comillas dobles** dentro de comillas dobles

**Soluciones:**
1. Usar `vagrant ssh <nodo>` para entrar a la VM y ejecutar comandos directamente en bash
2. Escribir SQL a un archivo en `/vagrant/` y ejecutarlo con `mysql < archivo.sql`
3. Usar `set +H` dentro de la VM para desactivar history expansion antes de comandos con `!`
