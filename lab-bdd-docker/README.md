# Laboratorio BDD — Docker

Implementación del laboratorio de Bases de Datos Distribuidas (Fases 0–16) usando Docker en lugar de VirtualBox + Ubuntu Server.

## Arquitectura

| Nodo | IP | server_id | Rol | Fase |
|------|----|-----------|-----|------|
| bdd-nodo01 | 192.168.56.101 | 1 | MAESTRO replicación física | 10 |
| bdd-nodo02 | 192.168.56.102 | 2 | ESCLAVO (read_only=ON) | 10 |
| bdd-nodo03 | 192.168.56.103 | 3 | MULTI-MAESTRO | 11 |
| bdd-nodo04 | 192.168.56.104 | 4 | SHARD A (norte + este) | 13 |
| bdd-nodo05 | 192.168.56.105 | 5 | SHARD B (sur + oeste) | 13 |
| bdd-nodo06 | 192.168.56.106 | 6 | COORDINADOR Spider | 14–16 |

Red: `192.168.56.0/24` — Puertos host: 3306→nodo01, 3307→nodo02, ..., 3311→nodo06

## Requisitos

- Docker Engine 24+
- Docker Compose v2+
- Cliente MySQL / MariaDB (opcional, para conexión desde host)

## Inicio rápido

```bash
cd lab-bdd-docker
docker compose build
docker compose up -d
```

Verificar estado:

```bash
docker compose ps
```

## Conexión a los nodos

```bash
# Desde el host (usando puertos mapeados)
mysql -h 127.0.0.1 -P 3306 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo01
mysql -h 127.0.0.1 -P 3307 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo02
mysql -h 127.0.0.1 -P 3308 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo03
mysql -h 127.0.0.1 -P 3309 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo04
mysql -h 127.0.0.1 -P 3310 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo05
mysql -h 127.0.0.1 -P 3311 -u lab_admin -p'LabAdmin_2025!' lab_bdd   # nodo06

# Dentro del contenedor
docker compose exec bdd-nodo01 mariadb -u root lab_bdd
```

## Usuarios

| Usuario | Contraseña | Alcance | Privilegios |
|---------|-----------|---------|-------------|
| root | LabAdmin_2025! | local + % | Superusuario |
| lab_admin | LabAdmin_2025! | localhost, % | ALL PRIVILEGES ON lab_bdd.* |
| app_user | AppUser_2025! | localhost, % | SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* |
| repl_user | ReplUser_2025! | % | REPLICATION SLAVE ON *.* |

Los usuarios `lab_admin` y `app_user` tienen variantes `@'localhost'` (socket Unix dentro del contenedor) y `@'%'` (conexiones TCP desde host/otros contenedores).

## Base de datos

### Esquema (`sql/01-schema.sql`)

- **clientes** (20) — `id`, `nombre`, `apellido`, `email`, `telefono`, `region` (norte/sur/este/oeste), `ciudad`, `fecha_alta`
- **productos** (10) — `id`, `sku`, `nombre`, `categoria`, `precio`, `stock`, `descripcion`, `ficha_tecnica`, `imagen_url`, `peso_kg`, `fecha_creacion`
- **pedidos** (20) — `id`, `cliente_id` (FK), `region`, `fecha_pedido`, `estado`, `total`
- **detalle_pedidos** (36) — `id`, `pedido_id` (FK), `producto_id` (FK), `cantidad`, `precio_unitario`, `subtotal` (generado)

### Datos de prueba (`sql/02-data.sql`)

- 20 clientes (5 por región: norte, sur, este, oeste)
- 10 productos (4 categorías)
- 20 pedidos con distintos estados
- 36 líneas de detalle (totales calculados automáticamente)

## Scripts de inicialización

Ejecutados en orden al primer arranque (controlado por `/var/lib/mysql/.init-complete`):

| Archivo | Contenido |
|---------|-----------|
| `sql/01-schema.sql` | CREATE DATABASE + tablas |
| `sql/02-data.sql` | Datos de prueba |
| `sql/03-users.sql` | Usuarios y privilegios |
| `sql/04-spider-setup.sql` | Tablas Spider en nodo06 (particionamiento) |

`sql/reference/commandos-de-monitoreo.sql` — comandos de monitoreo (no se ejecutan automáticamente).

## Replicación

### Física (Fase 10): nodo01 → nodo02

```bash
# Verificar maestro
docker compose exec bdd-nodo01 mariadb -u root -e "SHOW MASTER STATUS\G"

# Verificar esclavo
docker compose exec bdd-nodo02 mariadb -u root -e "SHOW SLAVE STATUS\G"

# Probar replicación
docker compose exec bdd-nodo01 mariadb lab_bdd \
  -e "INSERT INTO clientes (nombre,apellido,email,telefono,region,ciudad) VALUES ('Test','Docker','test@lab.test','5550000000','norte','CDMX');"
docker compose exec bdd-nodo02 mariadb lab_bdd \
  -e "SELECT id,nombre,apellido,email FROM clientes WHERE email='test@lab.test';"
```

### Lógica (Fase 11): nodo01 ↔ nodo03 (multi-maestro)

### Fragmentación (Fase 13): nodo04 (norte+este), nodo05 (sur+oeste)

### Spider (Fases 14–16): nodo06 como coordinador

```bash
docker compose exec bdd-nodo06 mariadb lab_bdd \
  -e "SELECT c.id, c.nombre, c.apellido, c.region, p.id, p.total FROM clientes_spider c JOIN pedidos_spider p ON c.id = p.cliente_id WHERE c.region = 'norte';"
```

## Notas

- MariaDB 10.11 LTS sobre Ubuntu 24.04 (misma versión que el laboratorio original)
- La replicación se configura automáticamente vía GTID (`MASTER_USE_GTID = slave_pos`)
- El motor Spider se activa en nodo06 con `plugin_load_add = ha_spider`
- Los datos persisten en volúmenes Docker (`vol_nodo01`–`vol_nodo06`)
- Sustituye completamente VirtualBox + VMs por contenedores
