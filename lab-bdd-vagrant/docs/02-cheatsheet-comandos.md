# Cheat Sheet — Comandos rápidos

## Vagrant

| Comando | Descripción |
|---------|-------------|
| `vagrant up bdd-nodo01` | Crear y provisionar nodo01 |
| `vagrant up bdd-nodo01 --no-provision` | Solo arrancar VM sin provisionar |
| `vagrant provision bdd-nodo01` | Ejecutar solo el provision |
| `vagrant ssh bdd-nodo01` | Conectarse por SSH al nodo |
| `vagrant halt bdd-nodo01` | Apagar la VM |
| `vagrant status bdd-nodo01` | Ver estado de la VM |
| `vagrant destroy bdd-nodo01` | Eliminar la VM por completo |

## MariaDB

| Comando | Descripción |
|---------|-------------|
| `mysql -u root -pLabAdmin_2025!` | Conectar a MariaDB como root |
| `SHOW MASTER STATUS\G` | Ver estado del binlog en el maestro |
| `SHOW SLAVE STATUS\G` | Ver estado de replicación en el esclavo |
| `STOP SLAVE; RESET SLAVE ALL;` | Reiniciar estado de replicación |
| `START SLAVE;` | Iniciar replicación |
| `SHOW DATABASES;` | Listar bases de datos |
| `USE lab_bdd; SHOW TABLES;` | Ver tablas de lab_bdd |
| `SELECT COUNT(*) FROM clientes;` | Contar registros en clientes |
| `SELECT * FROM clientes WHERE nombre LIKE 'Test%';` | Buscar registros |

## Solución de problemas

| Problema | Solución |
|----------|----------|
| Lock stale de Vagrant | `& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "bdd-nodo01" poweroff` |
| Error `!', event not found` | `set +H` antes del comando |
| Duplicate entry 1062 | Reset slave, dump & restore del maestro |
| `bind-address` solo 127.0.0.1 | `sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf` |

## Esquema de IPs

| Nodo | IP | Rol |
|------|----|-----|
| bdd-nodo01 | 192.168.56.101 | Maestro replicación física |
| bdd-nodo02 | 192.168.56.102 | Esclavo replicación física |
| bdd-nodo03 | 192.168.56.103 | Multi-maestro (lógica) |
| bdd-nodo04 | 192.168.56.104 | Shard A |
| bdd-nodo05 | 192.168.56.105 | Shard B |
| bdd-nodo06 | 192.168.56.106 | Coordinador Spider |

## Credenciales

| Usuario | Contraseña |
|---------|------------|
| root | LabAdmin_2025! |
| repl_user | ReplUser_2025! |
| app_user | (definida en 03-users.sql) |
| lab_admin | (definida en 03-users.sql) |
