-- ============================================================
-- FASE 13 — Fragmentación Horizontal
-- Basado en la implementación real del usuario
-- (VARCHAR en lugar de ENUM; cliente_id como en lab_bdd original)
-- ============================================================
-- NODOS: bdd-nodo04 (Shard A: norte+este)
--        bdd-nodo05 (Shard B: sur+oeste)
--        bdd-nodo01 (origen de datos)
-- ============================================================

-- ============================================================
-- PARTE 1: EN nodo01 — Preparar distribución de datos
-- ============================================================

-- 1a. Crear usuario shard_pull para mysqldump remoto
CREATE USER IF NOT EXISTS 'shard_pull'@'192.168.56.104'
  IDENTIFIED BY 'ShardPull_2025!';
GRANT SELECT ON lab_bdd.* TO 'shard_pull'@'192.168.56.104';

CREATE USER IF NOT EXISTS 'shard_pull'@'192.168.56.105'
  IDENTIFIED BY 'ShardPull_2025!';
GRANT SELECT ON lab_bdd.* TO 'shard_pull'@'192.168.56.105';

FLUSH PRIVILEGES;

SELECT User, Host FROM mysql.user WHERE User = 'shard_pull';

-- 1b. Materializar tablas temporales para detalle_pedidos (fragmentación derivada)
USE lab_bdd;

DROP TABLE IF EXISTS tmp_detalle_frag_A;
CREATE TABLE tmp_detalle_frag_A
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
SELECT dp.id, dp.pedido_id, dp.producto_id,
       dp.cantidad, dp.precio_unitario, dp.subtotal
FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('norte','este');

DROP TABLE IF EXISTS tmp_detalle_frag_B;
CREATE TABLE tmp_detalle_frag_B
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
SELECT dp.id, dp.pedido_id, dp.producto_id,
       dp.cantidad, dp.precio_unitario, dp.subtotal
FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('sur','oeste');

SELECT 'tmp_detalle_frag_A' AS fragmento, COUNT(*) AS filas
FROM tmp_detalle_frag_A
UNION ALL
SELECT 'tmp_detalle_frag_B', COUNT(*)
FROM tmp_detalle_frag_B
UNION ALL
SELECT 'detalle_pedidos (total original)', COUNT(*)
FROM detalle_pedidos;

-- ============================================================
-- PARTE 2: EN nodo04 (y nodo05) — Crear esquema lab_bdd
-- NOTA: region VARCHAR(10), estado VARCHAR(20); cliente_id como en lab_bdd
--       Sin FK (integridad por co-localización)
-- ============================================================

DROP DATABASE IF EXISTS lab_bdd;

CREATE DATABASE lab_bdd
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lab_bdd;

-- TABLA clientes
CREATE TABLE clientes (
  id                INT           NOT NULL AUTO_INCREMENT,
  nombre            VARCHAR(100)  NOT NULL,
  apellido          VARCHAR(100)  NOT NULL,
  email             VARCHAR(150),
  telefono          VARCHAR(20),
  region            VARCHAR(10)   NOT NULL,
  ciudad            VARCHAR(100),
  fecha_alta        DATETIME      DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_email (email),
  KEY idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fragmento horizontal de clientes — sin FK';

-- TABLA productos (catálogo completo en ambos shards)
CREATE TABLE productos (
  id              INT           NOT NULL AUTO_INCREMENT,
  sku             VARCHAR(50)   NOT NULL,
  nombre          VARCHAR(200)  NOT NULL,
  categoria       VARCHAR(100),
  descripcion     TEXT,
  ficha_tecnica   TEXT,
  imagen_url      VARCHAR(500),
  precio          DECIMAL(10,2) NOT NULL,
  stock           INT           DEFAULT 0,
  peso_kg         DECIMAL(8,3),
  fecha_creacion  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sku (sku)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo completo — fragmentación vertical en Fase 14';

-- TABLA pedidos (con cliente_id, region VARCHAR, estado VARCHAR)
CREATE TABLE IF NOT EXISTS pedidos (
  id            INT           NOT NULL AUTO_INCREMENT,
  cliente_id    INT           NOT NULL,
  region        VARCHAR(10)   NOT NULL,
  fecha_pedido  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  estado        VARCHAR(20)   DEFAULT 'pendiente',
  total         DECIMAL(10,2),
  PRIMARY KEY (id),
  KEY idx_cliente (cliente_id),
  KEY idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fragmento horizontal de pedidos — sin FK';

-- TABLA detalle_pedidos (sin region, co-localizada por pedido_id)
CREATE TABLE detalle_pedidos (
  id              INT           NOT NULL AUTO_INCREMENT,
  pedido_id       INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(10,2),
  PRIMARY KEY (id),
  KEY idx_pedido (pedido_id),
  KEY idx_producto (producto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fragmento derivado — co-localizado con pedidos';

SHOW TABLES IN lab_bdd;

-- ============================================================
-- PARTE 3: Cargar datos vía mysqldump (comandos SHELL, no SQL)
-- Ejecutar en nodo04/nodo05, NO dentro de mariadb
-- ============================================================

-- En nodo04 (frag_A):
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     --where="region IN ('norte','este')" \
--     lab_bdd clientes | sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     --where="region IN ('norte','este')" \
--     lab_bdd pedidos | sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     lab_bdd tmp_detalle_frag_A | \
--     sed 's/`tmp_detalle_frag_A`/`detalle_pedidos`/g' | \
--     sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     lab_bdd productos | sudo mariadb lab_bdd

-- En nodo05 (frag_B):
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     --where="region IN ('sur','oeste')" \
--     lab_bdd clientes | sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     --where="region IN ('sur','oeste')" \
--     lab_bdd pedidos | sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     lab_bdd tmp_detalle_frag_B | \
--     sed 's/`tmp_detalle_frag_B`/`detalle_pedidos`/g' | \
--     sudo mariadb lab_bdd
--
--   mysqldump -h 192.168.56.101 -u shard_pull -p'ShardPull_2025!' \
--     --no-create-info --skip-triggers \
--     lab_bdd productos | sudo mariadb lab_bdd

-- ============================================================
-- PARTE 4: En nodo04 y nodo05 — Verificar carga
-- ============================================================
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos;

-- ============================================================
-- PARTE 5: Verificaciones de correctitud
-- ============================================================

-- 5a. Disjunción en Shard A (nodo04): solo norte+este
SELECT 'Disjunción — clientes' AS verificacion,
       GROUP_CONCAT(DISTINCT region ORDER BY region) AS regiones_presentes,
       CASE
         WHEN GROUP_CONCAT(DISTINCT region ORDER BY region)
              IN ('este,norte', 'norte,este')
         THEN 'OK — solo frag_A (norte+este)'
         ELSE 'FALLA — hay regiones que no pertenecen a este shard'
       END AS resultado
FROM clientes;

SELECT 'Filas de frag_B en nodo04' AS verificacion,
       COUNT(*) AS filas_invalidas,
       CASE WHEN COUNT(*) = 0 THEN 'OK'
            ELSE 'FALLA' END AS resultado
FROM clientes
WHERE region IN ('sur', 'oeste');

-- 5b. Disjunción en Shard A — pedidos
SELECT 'Disjunción — pedidos' AS verificacion,
       GROUP_CONCAT(DISTINCT region ORDER BY region) AS regiones_presentes,
       CASE
         WHEN GROUP_CONCAT(DISTINCT region ORDER BY region)
              IN ('este,norte', 'norte,este')
         THEN 'OK — solo frag_A'
         ELSE 'FALLA'
       END AS resultado
FROM pedidos;

-- 5c. Co-localización detalle ↔ pedidos
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

-- 5d. Integridad cliente ↔ pedido
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

-- 5e. JOIN local completo
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

-- ============================================================
-- PARTE 6: En nodo01 — Verificar reconstrucción global
-- ============================================================
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

SELECT COUNT(*) AS clientes_reconstruidos
FROM (
  SELECT id, nombre, apellido, region FROM clientes
  WHERE region IN ('norte','este')
  UNION ALL
  SELECT id, nombre, apellido, region FROM clientes
  WHERE region IN ('sur','oeste')
) AS t;

SELECT region,
       COUNT(*) AS clientes,
       CASE
         WHEN region IN ('norte','este') THEN 'nodo04 (frag_A)'
         ELSE 'nodo05 (frag_B)'
       END AS shard_destino
FROM clientes
GROUP BY region
ORDER BY region;

-- ============================================================
-- PARTE 7: En nodo04/nodo05 — Otorgar SELECT a shard_verify
-- ============================================================
GRANT SELECT ON lab_bdd.* TO 'shard_verify'@'192.168.56.101';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'shard_verify'@'192.168.56.101';

-- ============================================================
-- PARTE 8: En nodo01 — Limpieza
-- ============================================================
DROP TABLE IF EXISTS lab_bdd.tmp_detalle_frag_A;
DROP TABLE IF EXISTS lab_bdd.tmp_detalle_frag_B;

DROP USER IF EXISTS 'shard_pull'@'192.168.56.104';
DROP USER IF EXISTS 'shard_pull'@'192.168.56.105';
FLUSH PRIVILEGES;
