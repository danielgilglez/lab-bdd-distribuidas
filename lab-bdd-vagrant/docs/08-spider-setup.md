# Fase 11 — Spider: Coordinador de Sharding

## Objetivo

Configurar **bdd-nodo06** como coordinador **MariaDB Spider** que distribuye consultas entre los shards **bdd-nodo04** (shard A: norte+este) y **bdd-nodo05** (shard B: sur+oeste), permitiendo consultas transparentes como si fuera una sola base de datos.

## Arquitectura

```
                     ┌─────────────────────┐
                     │   bdd-nodo06         │
                     │   Spider Coordinator │
                     │   ENGINE=SPIDER      │
                     └──────────┬──────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                                   ▼
   ┌─────────────────────┐             ┌─────────────────────┐
   │   bdd-nodo04        │             │   bdd-nodo05        │
   │   Shard A           │             │   Shard B           │
   │   norte + este      │             │   sur + oeste       │
   │   ENGINE=InnoDB     │             │   ENGINE=InnoDB     │
   └─────────────────────┘             └─────────────────────┘
```

## Tablas Spider

| Tabla Spider (nodo06) | Partition | Shard A | Shard B |
|----------------------|-----------|---------|---------|
| `clientes` | LIST COLUMNS (region) | norte, este | sur, oeste |
| `pedidos` | LIST COLUMNS (region) | norte, este | sur, oeste |
| `detalle_pedidos` | LIST (pedido_id MOD 2) | pares | impares |
| `productos_basico` | No | todos los productos | — |
| `productos_detalle` | No | — | todos los productos |

## Componentes del Setup

### 1. Paquete `mariadb-plugin-spider`

MariaDB 10.11 no incluye Spider por defecto. Se instaló en `provision-role.sh`:

```bash
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-plugin-spider
```

### 2. Configuración `plugin_load_add = ha_spider`

En `60-replication.cnf` para rol `spider`:

```ini
[mariadb]
server_id = 6
log_bin = /var/log/mysql/mariadb-bin
plugin_load_add = ha_spider
```

### 3. `CREATE SERVER` para definir conexiones

```sql
DROP SERVER IF EXISTS shard_a;
CREATE SERVER shard_a
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.104', PORT 3306, USER 'lab_admin', PASSWORD 'LabAdmin_2025!');

DROP SERVER IF EXISTS shard_b;
CREATE SERVER shard_b
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.105', PORT 3306, USER 'lab_admin', PASSWORD 'LabAdmin_2025!');
```

### 4. Tablas Spider con particionamiento

Ejemplo para `clientes`:

```sql
CREATE TABLE lab_bdd.clientes (
  id INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  ...
  region VARCHAR(10) NOT NULL,
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "clientes"'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION shard_a VALUES IN ('norte','este') COMMENT 'srv "shard_a"',
    PARTITION shard_b VALUES IN ('sur','oeste') COMMENT 'srv "shard_b"'
  );
```

**Nota**: La PK debe incluir la columna de partición (`PRIMARY KEY (id, region)`). Los UNIQUE INDEX deben incluir la columna de partición o eliminarse.

### 5. Script de setup

`sql/04-spider-setup.sql` ejecutado automáticamente en nodo06 durante `vagrant provision`.

## Problemas Encontrados y Soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| `Can't open shared library 'ha_spider.so'` | Falta `mariadb-plugin-spider` | Instalar con `apt-get install -y mariadb-plugin-spider` |
| `The connect info is invalid` | COMMENT multilínea mal parseado | Usar `CREATE SERVER` + `srv "name"` en lugar de inline host/port/user/password |
| `VALUES value for partition must have type INT` | ENUM no es INT para LIST | Usar `PARTITION BY LIST COLUMNS` para strings |
| `A PRIMARY KEY must include all columns in the table's partitioning function` | PK sin columna de partición | Incluir columna de partición en PK compuesta |
| `A UNIQUE INDEX must include all columns in the table's partitioning function` | UNIQUE sin columna de partición | Cambiar UNIQUE a INDEX normal |

## Verificación

```sql
-- Tablas Spider
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='lab_bdd' AND TABLE_TYPE='BASE TABLE';

-- Particiones
SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA='lab_bdd' AND TABLE_NAME IN ('clientes','pedidos','detalle_pedidos')
ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;

-- Consulta distribuida (JOIN cross-shard)
SELECT c.region,
  COUNT(DISTINCT c.id) AS clientes,
  COUNT(DISTINCT p.id) AS pedidos,
  COUNT(dp.id) AS detalle
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
JOIN detalle_pedidos dp ON p.id = dp.pedido_id
GROUP BY c.region ORDER BY c.region;
```

## Exportación OVA

Antes de exportar, el coordinador Spider debe tener la carpeta compartida de Vagrant removida:

```powershell
VBoxManage sharedfolder remove "bdd-nodo06" --name "vagrant"
VBoxManage export "bdd-nodo06" -o "ovas/bdd-nodo06.ova"
```

Ver referencias en `docs/05-sesion2-bddadmin-y-exportacion.md` para el proceso completo de exportación.
