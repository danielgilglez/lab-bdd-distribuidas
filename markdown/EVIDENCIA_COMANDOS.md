# Guía de Comandos para Evidencia (Fases 12–14)

Comandos extraídos **textualmente** de los PDFs/Markdown originales.
Ejecutar vía `vagrant ssh <nodo> -- <comando>` desde PowerShell del host,
o copiar/pegar directamente en una sesión SSH dentro del nodo.

---

## Fase 12 — Particionamiento de Tablas (bdd-nodo01)

> **Nota:** `lab_particiones.pedidos` usa `client_id` (Fase 12), pero `lab_bdd.pedidos` original
> usa `cliente_id`. Los scripts de Fases 13-14 usan `cliente_id` para coincidir con `lab_bdd`.
> Columnas `VARCHAR` (no `ENUM`). Ver `sql/fase12-completa.sql` para el script completo.

### 12.1 Ver el esquema `lab_particiones` y tipos de partición

```bash
sudo mariadb lab_particiones << 'EOF'
SELECT TABLE_NAME AS tabla,
       PARTITION_NAME AS particion,
       PARTITION_METHOD AS tipo,
       PARTITION_EXPRESSION AS expresion,
       PARTITION_DESCRIPTION AS definicion,
       TABLE_ROWS AS filas_est,
       ROUND(DATA_LENGTH / 1024.0, 2) AS datos_KB,
       ROUND(INDEX_LENGTH / 1024.0, 2) AS indices_KB
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;
EOF
```

### 12.2 Distribución de filas por partición

```bash
sudo mariadb lab_particiones << 'EOF'
-- clientes_list4 — 4 particiones (una por región)
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS region_cubierta,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list4'
ORDER BY PARTITION_ORDINAL_POSITION;

-- clientes_list2 — 2 particiones (frag_A / frag_B)
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list2'
ORDER BY PARTITION_ORDINAL_POSITION;

-- pedidos_rangos — RANGE por año
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS limite_superior,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_rangos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- pedidos — LIST COLUMNS (2 particiones: frag_A / frag_B)
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- accesos_hash — HASH
SELECT PARTITION_NAME AS particion,
       TABLE_ROWS AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'accesos_hash'
ORDER BY PARTITION_NAME;

-- log_eventos_key — KEY
SELECT PARTITION_NAME AS particion,
       TABLE_ROWS AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'log_eventos_key'
ORDER BY PARTITION_NAME;

-- clientes_subpart — Subparticiones LIST + HASH
SELECT PARTITION_NAME,
       SUBPARTITION_NAME,
       PARTITION_DESCRIPTION AS region,
       TABLE_ROWS AS filas_est
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_subpart'
ORDER BY PARTITION_ORDINAL_POSITION, SUBPARTITION_ORDINAL_POSITION;
EOF
```

### 12.3 Conteo total por tabla

```bash
sudo mariadb lab_particiones << 'EOF'
SELECT 'clientes_list4' AS tabla, COUNT(*) AS total FROM clientes_list4
UNION ALL
SELECT 'clientes_list2', COUNT(*) FROM clientes_list2
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'pedidos_rangos', COUNT(*) FROM pedidos_rangos
UNION ALL
SELECT 'accesos_hash', COUNT(*) FROM accesos_hash
UNION ALL
SELECT 'log_eventos_key', COUNT(*) FROM log_eventos_key
UNION ALL
SELECT 'clientes_subpart', COUNT(*) FROM clientes_subpart;
EOF
```

### 12.4 Poda de particiones (EXPLAIN)

```bash
sudo mariadb lab_particiones << 'EOF'
-- Con predicado exacto → solo 'p_norte'
EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region = 'norte';

-- Sin predicado → las cuatro particiones
EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4;

-- Con IN sobre dos valores → solo las particiones de esos valores
EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region IN ('norte', 'este');

-- RANGE — poda temporal
EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos
WHERE YEAR(fecha_pedido) = 2025;

-- Rango de dos años → dos particiones
EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos
WHERE fecha_pedido BETWEEN '2024-01-01' AND '2025-12-31';
EOF
```

### 12.5 Resumen: conteo exacto por partición

```bash
sudo mariadb lab_particiones << 'EOF'
SELECT 'p_norte (list4)' AS particion, COUNT(*) AS filas
FROM clientes_list4 WHERE region = 'norte' UNION ALL
SELECT 'p_sur (list4)', COUNT(*) FROM clientes_list4 WHERE region = 'sur' UNION ALL
SELECT 'p_este (list4)', COUNT(*) FROM clientes_list4 WHERE region = 'este' UNION ALL
SELECT 'p_oeste (list4)', COUNT(*) FROM clientes_list4 WHERE region = 'oeste' UNION ALL
SELECT 'frag_A (list2)', COUNT(*) FROM clientes_list2 WHERE region IN ('norte','este') UNION ALL
SELECT 'frag_B (list2)', COUNT(*) FROM clientes_list2 WHERE region IN ('sur','oeste');
EOF
```

### 12.6 Verificación de poda con EXPLAIN adicional

```bash
sudo mariadb lab_particiones << 'EOF'
-- Sin filtro temporal → todas las particiones, incluida p_futuro
EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos;

-- HASH: NO poda con predicados de negocio (usuario_id != id)
EXPLAIN SELECT COUNT(*)
FROM accesos_hash
WHERE usuario_id = 1;

-- HASH: poda SOLO con el atributo exacto (id)
EXPLAIN SELECT * FROM accesos_hash WHERE id = 42;
EOF
```

### 12.7 Auditoría con INFORMATION_SCHEMA.PARTITIONS (resumen)

```bash
sudo mariadb lab_particiones << 'EOF'
SELECT TABLE_NAME AS tabla,
       COUNT(PARTITION_NAME) AS num_particiones,
       SUM(TABLE_ROWS) AS filas_totales_est,
       ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024.0, 2) AS total_KB
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;
EOF
```

### 12.8 Operaciones de mantenimiento

```bash
sudo mariadb lab_particiones << 'EOF'
-- ADD PARTITION — agregar 'centro' a clientes_list4
ALTER TABLE clientes_list4 ADD PARTITION (PARTITION p_centro VALUES IN ('centro'));
INSERT INTO clientes_list4 (id, nombre, apellido, email, region, ciudad)
VALUES (21, 'Gabriela', 'Núñez', 'gabriela.nunez@lab.test', 'centro', 'CDMX');

-- REORGANIZE PARTITION — dividir frag_A en p_norte y p_este
ALTER TABLE clientes_list2
REORGANIZE PARTITION frag_A INTO (
  PARTITION p_norte VALUES IN ('norte'),
  PARTITION p_este  VALUES IN ('este')
);

-- TRUNCATE PARTITION — vaciar p_anterior (años < 2024)
ALTER TABLE pedidos_rangos TRUNCATE PARTITION p_anterior;

-- REORGANIZE — partir p_futuro en p_2027 + p_futuro
ALTER TABLE pedidos_rangos
REORGANIZE PARTITION p_futuro INTO (
  PARTITION p_2027   VALUES LESS THAN (2028),
  PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

-- DROP PARTITION — eliminar p_centro y sus datos
ALTER TABLE clientes_list4 DROP PARTITION p_centro;
EOF
```
EOF
```

---

## Fase 13 — Fragmentación Horizontal (nodo04, nodo05, nodo01)

> **Nota:** Los shards usan `cliente_id` (como en `lab_bdd.pedidos` original). La tabla `lab_particiones.pedidos` de Fase 12 es la única con `client_id`.

### 13.1 Resumen de datos en Shard A (nodo04)

```bash
sudo mariadb lab_bdd -e "
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos;"
```

### 13.2 Resumen de datos en Shard B (nodo05)

```bash
sudo mariadb lab_bdd -e "
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos;"
```

### 13.3 Verificación de disjunción en Shard A (nodo04)

Solo deben aparecer regiones `norte` y `este`.

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Disjunción — clientes' AS verificacion,
       GROUP_CONCAT(DISTINCT region ORDER BY region) AS regiones_presentes,
       CASE
         WHEN GROUP_CONCAT(DISTINCT region ORDER BY region)
              IN ('este,norte', 'norte,este')
         THEN 'OK — solo frag_A (norte+este)'
         ELSE 'FALLA — hay regiones que no pertenecen a este shard'
       END AS resultado
FROM clientes;

-- Filas de frag_B que NO deberían estar aquí
SELECT 'Filas de frag_B en nodo04' AS verificacion,
       COUNT(*) AS filas_invalidas,
       CASE WHEN COUNT(*) = 0 THEN 'OK'
            ELSE 'FALLA' END AS resultado
FROM clientes
WHERE region IN ('sur', 'oeste');
EOF
```

### 13.4 Verificación de disjunción en Shard B (nodo05)

Solo deben aparecer regiones `sur` y `oeste`.

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Disjunción — clientes' AS verificacion,
       GROUP_CONCAT(DISTINCT region ORDER BY region) AS regiones_presentes,
       CASE
         WHEN GROUP_CONCAT(DISTINCT region ORDER BY region)
              IN ('oeste,sur', 'sur,oeste')
         THEN 'OK — solo frag_B (sur+oeste)'
         ELSE 'FALLA — hay regiones que no pertenecen a este shard'
       END AS resultado
FROM clientes;

-- Filas de frag_A que NO deberían estar aquí
SELECT 'Filas de frag_A en nodo05' AS verificacion,
       COUNT(*) AS filas_invalidas,
       CASE WHEN COUNT(*) = 0 THEN 'OK'
            ELSE 'FALLA' END AS resultado
FROM clientes
WHERE region IN ('norte', 'este');
EOF
```

### 13.5 Co-localización en Shard A (nodo04)

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Co-localización detalle↔pedidos' AS verificacion,
       COUNT(*) AS detalles_sin_pedido_local,
       CASE
         WHEN COUNT(*) = 0 THEN 'OK — co-localización correcta'
         ELSE 'FALLA'
       END AS resultado
FROM detalle_pedidos dp
WHERE NOT EXISTS (
  SELECT 1 FROM pedidos p WHERE p.id = dp.pedido_id
);

SELECT 'Integridad cliente↔pedido' AS verificacion,
       COUNT(*) AS pedidos_sin_cliente_local,
       CASE
         WHEN COUNT(*) = 0 THEN 'OK — integridad preservada'
         ELSE 'ADVERTENCIA'
       END AS resultado
FROM pedidos p
WHERE NOT EXISTS (
  SELECT 1 FROM clientes c WHERE c.id = p.cliente_id
);
EOF
```

### 13.6 Reconstrucción global desde nodo01 (verificación de completitud)

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Completitud clientes' AS condicion,
       (SELECT COUNT(*) FROM clientes) AS total_global,
       (SELECT COUNT(*) FROM clientes WHERE region IN ('norte','este')) +
       (SELECT COUNT(*) FROM clientes WHERE region IN ('sur','oeste')) AS suma_fragmentos,
       CASE
         WHEN (SELECT COUNT(*) FROM clientes) =
              (SELECT COUNT(*) FROM clientes WHERE region IN ('norte','este')) +
              (SELECT COUNT(*) FROM clientes WHERE region IN ('sur','oeste'))
         THEN 'OK' ELSE 'FALLA'
       END AS resultado;
EOF
```

### 13.7 Verificación cruzada: nodo01 consulta los shards remotamente

```bash
echo "=== nodo04 (frag_A) ==="
mysql -h 192.168.56.104 -u shard_verify -p'ShardVerify_2025!' lab_bdd \
  -e "SELECT 'clientes' AS t, COUNT(*) AS n FROM clientes
       UNION ALL
       SELECT 'pedidos', COUNT(*) FROM pedidos
       UNION ALL
       SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
       UNION ALL
       SELECT 'productos', COUNT(*) FROM productos;" 2>/dev/null

echo ""
echo "=== nodo05 (frag_B) ==="
mysql -h 192.168.56.105 -u shard_verify -p'ShardVerify_2025!' lab_bdd \
  -e "SELECT 'clientes' AS t, COUNT(*) AS n FROM clientes
       UNION ALL
       SELECT 'pedidos', COUNT(*) FROM pedidos
       UNION ALL
       SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
       UNION ALL
       SELECT 'productos', COUNT(*) FROM productos;" 2>/dev/null
```

### 13.8 JOIN local completo en Shard A (nodo04)

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT c.region,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       p.id AS pedido_id,
       p.estado,
       COUNT(dp.id) AS lineas_detalle,
       ROUND(SUM(dp.subtotal), 2) AS total_calculado,
       p.total AS total_registrado
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
GROUP BY c.region, c.id, p.id
ORDER BY c.region, p.id;
EOF
```

---

## Fase 14 — Fragmentación Vertical + Spider (nodo06, nodo04, nodo05)

> **Nota:** El coordinador Spider usa `cliente_id` (como en `lab_bdd.pedidos` original) y `VARCHAR` para `region`/`estado`. Ajusta a `ENUM` si tu `lab_bdd` usa ENUM.

### 14.1 Crear `v_productos_basico` en nodo04 (debe mostrar 10 filas)

```bash
sudo mariadb lab_bdd << 'EOF'
CREATE TABLE IF NOT EXISTS v_productos_basico (
  id INT NOT NULL AUTO_INCREMENT,
  sku VARCHAR(50) NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  categoria VARCHAR(100),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sku (sku)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Fragmento vertical basico de productos — Fase 14';

INSERT INTO v_productos_basico
  (id, sku, nombre, categoria, precio, stock, fecha_creacion)
SELECT id, sku, nombre, categoria, precio, stock, fecha_creacion
FROM productos;

SELECT 'Filas en v_productos_basico' AS metrica, COUNT(*) AS valor
FROM v_productos_basico;

SELECT id, sku, nombre, categoria, precio, stock
FROM v_productos_basico
ORDER BY id;
EOF
```

### 14.2 Crear `v_productos_detalle` en nodo05 (debe mostrar 10 filas)

```bash
sudo mariadb lab_bdd << 'EOF'
CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id INT NOT NULL,
  sku VARCHAR(50) NOT NULL,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(500),
  peso_kg DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Fragmento vertical detalle de productos — Fase 14';

INSERT INTO v_productos_detalle
  (id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg)
SELECT id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos;

SELECT 'Filas en v_productos_detalle' AS metrica, COUNT(*) AS valor
FROM v_productos_detalle;

SELECT id, sku,
       LEFT(descripcion, 50) AS descripcion_preview,
       LEFT(ficha_tecnica, 50) AS ficha_preview,
       imagen_url,
       peso_kg
FROM v_productos_detalle
ORDER BY id;
EOF
```

### 14.3 Verificar correctitud de fragmentación vertical en nodo04

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Completitud V_productos_basico' AS condicion,
       (SELECT COUNT(*) FROM productos) AS total_original,
       COUNT(*) AS filas_en_fragmento,
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
            THEN 'OK' ELSE 'FALLA'
       END AS resultado
FROM v_productos_basico;

SELECT 'Disjunción columnas V_productos_basico' AS condicion,
       CASE WHEN COUNT(*) = 0
            THEN 'OK — sin columnas de detalle'
            ELSE CONCAT('FALLA — columnas encontradas: ', GROUP_CONCAT(COLUMN_NAME))
       END AS resultado
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND TABLE_NAME = 'v_productos_basico'
  AND COLUMN_NAME IN ('descripcion','ficha_tecnica','imagen_url','peso_kg');
EOF
```

### 14.4 Verificar correctitud de fragmentación vertical en nodo05

```bash
sudo mariadb lab_bdd << 'EOF'
SELECT 'Completitud V_productos_detalle' AS condicion,
       (SELECT COUNT(*) FROM productos) AS total_original,
       COUNT(*) AS filas_en_fragmento,
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
            THEN 'OK' ELSE 'FALLA'
       END AS resultado
FROM v_productos_detalle;

SELECT 'Disjunción columnas V_productos_detalle' AS condicion,
       CASE WHEN COUNT(*) = 0
            THEN 'OK — sin columnas operacionales'
            ELSE CONCAT('FALLA — columnas encontradas: ', GROUP_CONCAT(COLUMN_NAME))
       END AS resultado
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND TABLE_NAME = 'v_productos_detalle'
  AND COLUMN_NAME IN ('nombre','categoria','precio','stock','fecha_creacion');

SELECT 'Reconstrucción (IDs coincidentes)' AS condicion,
       (SELECT COUNT(*) FROM productos) AS total_original,
       COUNT(*) AS filas_reconstruidas,
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
            THEN 'OK' ELSE 'FALLA'
       END AS resultado
FROM v_productos_detalle d
JOIN productos p ON p.id = d.id;
EOF
```

### 14.5 Plugin Spider activo en nodo06

```bash
sudo mariadb -e "
SELECT PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_STATUS, PLUGIN_TYPE
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'SPIDER';
"
```

### 14.6 Variables del coordinador en nodo06

```bash
sudo mariadb -e "
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'read_only';
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'skip_name_resolve';
"
```

### 14.7 Crear servidores remotos en nodo06

```bash
sudo mariadb -e "
CREATE SERVER IF NOT EXISTS srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.104', PORT 3306, DATABASE 'lab_bdd', USER 'spider_user', PASSWORD 'Spider_2025!');

CREATE SERVER IF NOT EXISTS srv_nodo05
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.105', PORT 3306, DATABASE 'lab_bdd', USER 'spider_user', PASSWORD 'Spider_2025!');

SELECT Server_name AS servidor, Host AS ip, Db AS base_datos,
       Username AS usuario, Port AS puerto
FROM mysql.servers
ORDER BY Server_name;
"
```

### 14.8 Crear tablas Spider y verificar fragmentos horizontales en nodo06

```bash
sudo mariadb << 'EOF'
CREATE DATABASE IF NOT EXISTS lab_bdd
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE lab_bdd;

-- clientes (particionada por región)
CREATE TABLE IF NOT EXISTS clientes (
  id INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150),
  telefono VARCHAR(20),
  region VARCHAR(10) NOT NULL,
  ciudad VARCHAR(100),
  fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id, region)
) ENGINE = SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "clientes"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "clientes"'
  );

-- pedidos (particionada por región)
CREATE TABLE IF NOT EXISTS pedidos (
  id INT NOT NULL AUTO_INCREMENT,
  cliente_id INT NOT NULL,
  region VARCHAR(10) NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) DEFAULT 'pendiente',
  total DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE = SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "pedidos"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "pedidos"'
  );

-- spider_detalle_nodo04 (Spider simple → nodo04)
CREATE TABLE IF NOT EXISTS spider_detalle_nodo04 (
  id INT NOT NULL AUTO_INCREMENT,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo04", table "detalle_pedidos"';

-- spider_detalle_nodo05 (Spider simple → nodo05)
CREATE TABLE IF NOT EXISTS spider_detalle_nodo05 (
  id INT NOT NULL AUTO_INCREMENT,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo05", table "detalle_pedidos"';

-- VIEW que unifica ambos shards
CREATE OR REPLACE VIEW detalle_pedidos AS
  SELECT * FROM spider_detalle_nodo04
  UNION ALL
  SELECT * FROM spider_detalle_nodo05;

-- Verificación inmediata
SELECT 'clientes (Spider, 2 shards)' AS fuente, COUNT(*) AS filas
FROM clientes
UNION ALL
SELECT 'pedidos (Spider, 2 shards)', COUNT(*)
FROM pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*)
FROM detalle_pedidos;
EOF
```

### 14.9 Crear tablas Spider verticales y VIEW productos en nodo06

```bash
sudo mariadb lab_bdd << 'EOF'
-- v_productos_basico → nodo04
CREATE TABLE IF NOT EXISTS v_productos_basico (
  id INT NOT NULL AUTO_INCREMENT,
  sku VARCHAR(50) NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  categoria VARCHAR(100),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sku (sku)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo04", table "v_productos_basico"';

-- v_productos_detalle → nodo05
CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id INT NOT NULL,
  sku VARCHAR(50) NOT NULL,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(500),
  peso_kg DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo05", table "v_productos_detalle"';

-- VIEW productos (JOIN distribuido)
CREATE OR REPLACE VIEW productos AS
  SELECT b.id, b.sku, b.nombre, b.categoria, b.precio, b.stock,
         d.descripcion, d.ficha_tecnica, d.imagen_url, d.peso_kg,
         b.fecha_creacion
  FROM v_productos_basico b
  JOIN v_productos_detalle d ON b.id = d.id;

-- Verificación
SELECT 'v_productos_basico (Spider → nodo04)' AS fuente, COUNT(*) AS productos
FROM v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider → nodo05)', COUNT(*)
FROM v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN distribuido)', COUNT(*)
FROM productos;

-- Inspección del primer producto reconstruido
SELECT id, sku, nombre, categoria, precio, stock,
       LEFT(descripcion, 50) AS descripcion_preview,
       peso_kg
FROM productos
WHERE id = 1;
EOF
```

### 14.10 Consultas distribuidas desde nodo06

```bash
sudo mariadb lab_bdd << 'EOF'
-- CONSULTA 1: Clientes de una sola región — poda Spider activa
SELECT id, CONCAT(nombre, ' ', apellido) AS cliente, region, ciudad
FROM clientes
WHERE region = 'norte'
ORDER BY id;

-- CONSULTA 2: Conteo de clientes por región (ambos shards)
SELECT region, COUNT(*) AS clientes_por_region
FROM clientes
GROUP BY region
ORDER BY region;

-- CONSULTA 3: Productos con stock (solo v_productos_basico → nodo04)
SELECT sku, nombre, categoria, precio, stock
FROM v_productos_basico
WHERE stock > 0
ORDER BY precio DESC;

-- CONSULTA 4: Ficha completa de un producto (JOIN distribuido)
SELECT id, sku, nombre, categoria, precio, stock,
       descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos
WHERE id = 2;

-- CONSULTA 5: Pedidos con datos de cliente (JOIN en shards con poda)
SELECT c.region,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       p.id AS pedido, p.estado, p.total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
ORDER BY c.region, p.id;

-- CONSULTA 6: HÍBRIDA — facturación por región
SELECT c.region,
       COUNT(DISTINCT c.id) AS clientes_activos,
       COUNT(DISTINCT p.id) AS num_pedidos,
       GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria) AS categorias,
       ROUND(SUM(dp.subtotal), 2) AS facturacion_total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id
GROUP BY c.region
ORDER BY facturacion_total DESC;

-- RESUMEN GLOBAL
SELECT 'clientes (2 shards, PARTITION Spider)' AS metrica, COUNT(*) AS valor FROM clientes
UNION ALL
SELECT 'pedidos (2 shards, PARTITION Spider)', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*) FROM detalle_pedidos
UNION ALL
SELECT 'v_productos_basico (Spider → nodo04)', COUNT(*) FROM v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider → nodo05)', COUNT(*) FROM v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN distribuido)', COUNT(*) FROM productos;
EOF
```

### 14.11 Verificación de conectividad Spider desde nodo06

```bash
# Verificar acceso a nodo04
mysql -h 192.168.56.104 -P 3306 -u spider_user -p'Spider_2025!' \
  -e "SELECT 'nodo04 accesible' AS estado, @@hostname AS host, @@server_id AS srv_id;" 2>&1

# Verificar acceso a nodo05
mysql -h 192.168.56.105 -P 3306 -u spider_user -p'Spider_2025!' \
  -e "SELECT 'nodo05 accesible' AS estado, @@hostname AS host, @@server_id AS srv_id;" 2>&1
```

---

## Resumen de comandos por nodo

| Nodo | Fase 12 | Fase 13 | Fase 14 |
|------|---------|---------|---------|
| bdd-nodo01 | 12.1–12.5 | 13.6, 13.7 | — |
| bdd-nodo04 | — | 13.1, 13.3, 13.5, 13.8 | 14.1, 14.3 |
| bdd-nodo05 | — | 13.2, 13.4 | 14.2, 14.4 |
| bdd-nodo06 | — | — | 14.5–14.11 |
