# Troubleshooting SSH en VMs — Guía para Agentes AI

## Problema recurrente: `vagrant up` falla con "Authentication failure"

### Síntomas

```
bdd-nodo0X: Warning: Authentication failure. Retrying...
bdd-nodo0X: Warning: Authentication failure. Retrying...
...
```

El comando `vagrant up` se queda intentando autenticar indefinidamente
hasta agotar el timeout (>5 minutos).

### Causa raíz

La línea dinámica del `Vagrantfile`:

```ruby
config.ssh.username = Dir.glob(".vagrant/machines/*/virtualbox/id").any? ? "bddadmin" : "vagrant"
```

Cuando el archivo `.vagrant/machines/*/virtualbox/id` **existe** (porque
la VM ya fue creada antes), Vagrant intenta conectar como `bddadmin`.
Pero si el snapshot restaurado es anterior a la creación del usuario
`bddadmin`, ese usuario **no existe** dentro de la VM y la autenticación
falla.

**¿Por qué existe el archivo `id` pero no el usuario `bddadmin`?**

El snapshot `fase10-completa` se tomó en la Fase 10, ANTES de que se
creara el usuario `bddadmin` (Sesión 2, posterior). Al restaurar el
snapshot, la VM vuelve a ese estado. Pero Vagrant mantiene el archivo
`id` en el host, lo que confunde al selector de usuario.

### Solución inmediata (menos pasos, menos tokens)

```bash
# 1. Conectar como vagrant con la clave insegura por defecto
ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1

# 2. Verificar si bddadmin existe
id bddadmin

# 3. Si no existe, volver a ejecutar el provisionamiento base
sudo bash /vagrant/scripts/provision-base.sh

# 4. Opcional: regenerar el estado de Vagrant
vagrant reload <NODO>
```

### Solución definitiva

Actualizar el snapshot para que incluya `bddadmin`:

```bash
# 1. Una vez dentro de la VM como vagrant, crear bddadmin
sudo bash /vagrant/scripts/provision-base.sh

# 2. Tomar nuevo snapshot
VBoxManage snapshot bdd-nodo01 take "fase10-completa-con-bddadmin"
```

O alternativamente, modificar el Vagrantfile para tener un fallback:

```ruby
config.ssh.username = "bddadmin"  # fijo, sin lógica dinámica
```

---

## Problema: SSH responde pero Vagrant dice "Authentication failure"

### Síntomas

```
ssh -v -p <PORT> vagrant@127.0.0.1
debug1: Connection established.
debug1: Local version string SSH-2.0-OpenSSH_for_Windows_9.5
# Se queda colgado aquí, nunca recibe banner del servidor
```

La conexión TCP se establece pero el servidor SSH no envía su banner.

### Causa raíz

La VM está encendida (`running` en VirtualBox) pero **el servicio SSH
no está iniciado**. La causa más común:

1. La VM fue apagada forzosamente (`VBoxManage controlvm poweroff`)
   mientras estaba en medio de operaciones de escritura (snapshot restore
   + poweroff simultáneo).
2. Al reiniciar, el kernel detecta un sistema de archivos sucio y ejecuta
   `fsck` en modo recovery, o se queda en un shell de rescate.
3. El servicio `ssh` no arranca porque el sistema no completó el boot.

### Solución

```bash
# 1. Forzar apagado y restaurar snapshot conocido-bueno
VBoxManage controlvm bdd-nodo0X poweroff
VBoxManage snapshot bdd-nodo0X restorecurrent

# 2. Arrancar con Vagrant (NO con VBoxManage startvm directo)
#    Vagrant configura port forwarding y espera el boot completo
vagrant reload bdd-nodo0X
```

**Importante:** Siempre usar `vagrant up` o `vagrant reload` para
arrancar las VMs, **no** `VBoxManage startvm`. Vagrant se encarga de:
- Configurar port forwarding correctamente
- Esperar a que SSH esté disponible
- Manejar el aprovisionamiento

---

## Problema: El archivo `private_key` falta en `.vagrant/machines/`

### Síntomas

```
Warning: Identity file .vagrant\machines\bdd-nodo0X\virtualbox\private_key
not accessible: No such file or directory
```

### Causa raíz

Vagrant genera un par de claves SSH por VM y guarda la clave privada
en `.vagrant/machines/<nombre>/virtualbox/private_key`. Este archivo
puede desaparecer si:

- Se elimina la carpeta `.vagrant/` manualmente
- Se corrompe durante un corte de energía o cierre forzado
- Se restaura un snapshot (Vagrant no regenera la clave automáticamente)

### Solución

```bash
# Opción 1: Usar la clave insegura global de Vagrant directamente
ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1

# Opción 2: Regenerar el estado Vagrant (peligroso, puede perder config)
rm -rf .vagrant/machines/bdd-nodo0X
vagrant up bdd-nodo0X --provision  # Reprovisiona desde cero

# Opción 3: Configurar el Vagrantfile para usar la clave global
# En Vagrantfile, agregar:
config.ssh.private_key_path = ["~/.vagrant.d/insecure_private_key"]
```

---

## Diagnóstico rápido (checklist para el agente AI)

Cuando `vagrant up` falle con error SSH, ejecutar en orden:

```bash
# 1. ¿La VM está running?
vagrant status <NODO>

# 2. ¿Está el puerto SSH abierto?
netstat -ano | findstr ":22[0-9][0-9]"

# 3. ¿Responde SSH como vagrant?
ssh -p <PORT> -o ConnectTimeout=5 -i ~/.vagrant.d/insecure_private_key \
    vagrant@127.0.0.1 "echo CONECTADO"
#   → Si NO responde: restaurar snapshot + vagrant reload (ver arriba)
#   → Si responde: el problema es de autenticación (usuario bddadmin)

# 4. ¿Existe bddadmin dentro de la VM?
ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key \
    vagrant@127.0.0.1 "id bddadmin"
#   → Si NO existe: ejecutar provision-base.sh

# 5. Alternativa: comprobar con -v para ver dónde falla
ssh -v -p <PORT> -i ~/.vagrant.d/insecure_private_key \
    vagrant@127.0.0.1 "echo CONECTADO" 2>&1 | grep -E "debug1|error|fail"
```

---

## Resumen de comandos útiles

| Acción | Comando |
|--------|---------|
| Conectar como vagrant | `ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1` |
| Ejecutar SQL en nodo01 | `ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1 "sudo mariadb -u root -p'LabAdmin_2025!' -e 'QUERY'"` |
| Ejecutar script SQL | `ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1 "sudo mariadb -u root -p'LabAdmin_2025!' < /vagrant/sql/ARCHIVO.sql"` |
| Crear bddadmin | `ssh -p <PORT> -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1 "sudo bash /vagrant/scripts/provision-base.sh"` |
| Restaurar snapshot | `VBoxManage controlvm bdd-nodo0X poweroff; VBoxManage snapshot bdd-nodo0X restorecurrent; vagrant reload bdd-nodo0X` |

---

## Notas importantes

- **Siempre** usar `vagrant up`/`vagrant reload`, nunca `VBoxManage startvm`
  directamente, para evitar problemas de port forwarding y SSH.
- Las VMs tienen `vb.gui = true` en el Vagrantfile, lo que puede retrasar
  el arranque. Tener paciencia con los timeouts (configurados a 900s).
- La clave insegura global está en: `~/.vagrant.d/insecure_private_key`
  (Windows: `$env:USERPROFILE\.vagrant.d\insecure_private_key`)
- El snapshot `fase10-completa` NO incluye al usuario `bddadmin`.
  El snapshot `fase10-completa-nodo03-fixed` SÍ lo incluye.
