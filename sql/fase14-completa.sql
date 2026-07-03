-- ============================================================
-- FASE 14 — Fragmentación Vertical + Spider Coordinator
-- Basado en la implementación real del usuario
-- (VARCHAR en lugar de ENUM; cliente_id en lab_bdd original)
-- ============================================================
-- NODOS: bdd-nodo04 (Shard A: v_productos_basico, datos horizontales)
--        bdd-nodo05 (Shard B: v_productos_detalle, datos horizontales)
--        bdd-nodo06 (Coordinador Spider)
-- ============================================================

-- ============================================================
-- PARTE 1: En nodo04 y nodo05 — Crear usuario spider_user
-- ============================================================
CREATE USER IF NOT EXISTS 'spider_user'@'192.168.56.106'
  IDENTIFIED BY 'Spider_2025!';

GRANT SELECT, INSERT, UPDATE, DELETE
  ON lab_bdd.*
  TO 'spider_user'@'192.168.56.106';

FLUSH PRIVILEGES;

SELECT User, Host FROM mysql.user WHERE User = 'spider_user';
SHOW GRANTS FOR 'spider_user'@'192.168.56.106';

-- ============================================================
-- PARTE 2: En nodo04 — Crear v_productos_basico (fragmento vertical)
-- ============================================================
CREATE TABLE IF NOT EXISTS v_productos_basico (
  id              INT           NOT NULL AUTO_INCREMENT,
  sku             VARCHAR(50)   NOT NULL,
  nombre          VARCHAR(200)  NOT NULL,
  categoria       VARCHAR(100),
  precio          DECIMAL(10,2) NOT NULL,
  stock           INT           DEFAULT 0,
  fecha_creacion  DATETIME      DEFAULT CURRENT_TIMESTAMP,
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

-- Verificar completitud y disjunción
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

-- ============================================================
-- PARTE 3: En nodo05 — Crear v_productos_detalle (fragmento vertical)
-- ============================================================
CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id              INT           NOT NULL,
  sku             VARCHAR(50)   NOT NULL,
  descripcion     TEXT,
  ficha_tecnica   TEXT,
  imagen_url      VARCHAR(500),
  peso_kg         DECIMAL(8,3),
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

-- Verificar completitud, disjunción y reconstrucción
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

-- ============================================================
-- PARTE 4: En nodo06 — Instalar plugin Spider
-- ============================================================
INSTALL SONAME 'ha_spider';

SELECT PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_STATUS, PLUGIN_TYPE
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'SPIDER';

-- ============================================================
-- PARTE 5: En nodo06 — CREATE SERVER (registrar shards remotos)
-- ============================================================
CREATE SERVER IF NOT EXISTS srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (
  HOST '192.168.56.104',
  PORT 3306,
  DATABASE 'lab_bdd',
  USER 'spider_user',
  PASSWORD 'Spider_2025!'
);

CREATE SERVER IF NOT EXISTS srv_nodo05
FOREIGN DATA WRAPPER mysql
OPTIONS (
  HOST '192.168.56.105',
  PORT 3306,
  DATABASE 'lab_bdd',
  USER 'spider_user',
  PASSWORD 'Spider_2025!'
);

SELECT Server_name AS servidor, Host AS ip, Db AS base_datos,
       Username AS usuario, Port AS puerto
FROM mysql.servers
ORDER BY Server_name;

-- ============================================================
-- PARTE 6: En nodo06 — Crear lab_bdd y tablas Spider
--           (cliente_id, VARCHAR para consistencia con shards)
-- ============================================================
CREATE DATABASE IF NOT EXISTS lab_bdd
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lab_bdd;

-- 6a. clientes — Spider particionada por LIST COLUMNS (region)
CREATE TABLE IF NOT EXISTS clientes (
  id                  INT           NOT NULL AUTO_INCREMENT,
  nombre              VARCHAR(100)  NOT NULL,
  apellido            VARCHAR(100)  NOT NULL,
  email               VARCHAR(150),
  telefono            VARCHAR(20),
  region              VARCHAR(10)   NOT NULL,
  ciudad              VARCHAR(100),
  fecha_alta          DATETIME      DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion DATETIME      DEFAULT NULL,
  PRIMARY KEY (id, region)
) ENGINE = SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "clientes"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "clientes"'
  );

-- 6b. pedidos — Spider particionada (cliente_id, VARCHAR)
CREATE TABLE IF NOT EXISTS pedidos (
  id            INT           NOT NULL AUTO_INCREMENT,
  cliente_id    INT           NOT NULL,
  region        VARCHAR(10)   NOT NULL,
  fecha_pedido  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  estado        VARCHAR(20)   DEFAULT 'pendiente',
  total         DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE = SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "pedidos"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "pedidos"'
  );

-- 6c. spider_detalle_nodo04 — Spider simple → nodo04
CREATE TABLE IF NOT EXISTS spider_detalle_nodo04 (
  id              INT           NOT NULL AUTO_INCREMENT,
  pedido_id       INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo04", table "detalle_pedidos"';

-- 6d. spider_detalle_nodo05 — Spider simple → nodo05
CREATE TABLE IF NOT EXISTS spider_detalle_nodo05 (
  id              INT           NOT NULL AUTO_INCREMENT,
  pedido_id       INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo05", table "detalle_pedidos"';

-- 6e. VIEW detalle_pedidos (UNION ALL de ambos shards)
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

-- ============================================================
-- PARTE 7: En nodo06 — Tablas Spider para fragmentos verticales
-- ============================================================

-- 7a. v_productos_basico → nodo04
CREATE TABLE IF NOT EXISTS v_productos_basico (
  id              INT           NOT NULL AUTO_INCREMENT,
  sku             VARCHAR(50)   NOT NULL,
  nombre          VARCHAR(200)  NOT NULL,
  categoria       VARCHAR(100),
  precio          DECIMAL(10,2) NOT NULL,
  stock           INT           DEFAULT 0,
  fecha_creacion  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sku (sku)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo04", table "v_productos_basico"';

-- 7b. v_productos_detalle → nodo05
CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id              INT           NOT NULL,
  sku             VARCHAR(50)   NOT NULL,
  descripcion     TEXT,
  ficha_tecnica   TEXT,
  imagen_url      VARCHAR(500),
  peso_kg         DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE = SPIDER
  COMMENT = 'server "srv_nodo05", table "v_productos_detalle"';

-- 7c. VIEW productos (JOIN distribuido entre fragmentos verticales)
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

-- ============================================================
-- PARTE 8: En nodo06 — Consultas distribuidas de verificación
-- ============================================================

-- Consulta 1: Clientes de una sola región — poda Spider activa
SELECT id, CONCAT(nombre, ' ', apellido) AS cliente, region, ciudad
FROM clientes
WHERE region = 'norte'
ORDER BY id;

-- Consulta 2: Conteo de clientes por región (ambos shards)
SELECT region, COUNT(*) AS clientes_por_region
FROM clientes
GROUP BY region
ORDER BY region;

-- Consulta 3: Productos con stock (v_productos_basico → nodo04)
SELECT sku, nombre, categoria, precio, stock
FROM v_productos_basico
WHERE stock > 0
ORDER BY precio DESC;

-- Consulta 4: Ficha completa de un producto (JOIN distribuido)
SELECT id, sku, nombre, categoria, precio, stock,
       descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos
WHERE id = 2;

-- Consulta 5: Pedidos con datos de cliente (JOIN en shards)
SELECT c.region,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       p.id AS pedido, p.estado, p.total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
ORDER BY c.region, p.id;

-- Consulta 6: Híbrida — facturación por región
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

-- Resumen global
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
