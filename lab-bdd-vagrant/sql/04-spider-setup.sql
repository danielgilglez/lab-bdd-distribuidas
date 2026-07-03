-- ============================================================================
-- Fase 14 — Configuración del coordinador Spider (bdd-nodo06)
--
-- Crea:
--   1. Plugin Spider (INSTALL SONAME 'ha_spider')
--   2. Servidores remotos (CREATE SERVER para nodo04 y nodo05)
--   3. Tablas Spider particionadas: clientes, pedidos
--   4. Tablas Spider simples: spider_detalle_nodo04, spider_detalle_nodo05
--   5. Tablas Spider para fragmentos verticales: v_productos_basico, v_productos_detalle
--   6. VIEWs: detalle_pedidos (UNION ALL), productos (JOIN distribuido)
--
-- Nota: region se define como VARCHAR(10) para coincidir con el esquema
-- real de los shards (convertido de ENUM en 04-fix-shard-schema.sql).
-- ============================================================================

-- ============================================================================
-- 1. INSTALAR PLUGIN SPIDER
-- ============================================================================
INSTALL SONAME 'ha_spider';

-- ============================================================================
-- 2. REGISTRAR SERVIDORES REMOTOS
-- ============================================================================
SET foreign_key_checks = 0;

-- Limpiar servidores antiguos (nombres de implementaciones previas)
DROP SERVER IF EXISTS shard_a;
DROP SERVER IF EXISTS shard_b;

DROP SERVER IF EXISTS srv_nodo04;
CREATE SERVER srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (
  HOST '192.168.56.104',
  PORT 3306,
  DATABASE 'lab_bdd',
  USER 'spider_user',
  PASSWORD 'Spider_2025!'
);

DROP SERVER IF EXISTS srv_nodo05;
CREATE SERVER srv_nodo05
FOREIGN DATA WRAPPER mysql
OPTIONS (
  HOST '192.168.56.105',
  PORT 3306,
  DATABASE 'lab_bdd',
  USER 'spider_user',
  PASSWORD 'Spider_2025!'
);

-- ============================================================================
-- 3. CREAR BASE DE DATOS
-- ============================================================================
CREATE DATABASE IF NOT EXISTS lab_bdd
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE lab_bdd;

-- Limpiar tablas con nombres antiguos (de implementaciones previas)
DROP TABLE IF EXISTS productos_basico, productos_detalle;
DROP TABLE IF EXISTS detalle_pedidos;

-- ============================================================================
-- 4. TABLAS SPIDER — FRAGMENTACIÓN HORIZONTAL (PARTITION BY LIST COLUMNS)
-- ============================================================================

-- --------------------------------------------------------------------------
-- 4.1 clientes
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS clientes;
CREATE TABLE clientes (
  id INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150),
  telefono VARCHAR(20),
  region VARCHAR(10) NOT NULL,
  ciudad VARCHAR(100),
  fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion DATETIME DEFAULT NULL,
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "clientes"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "clientes"'
  );

-- --------------------------------------------------------------------------
-- 4.2 pedidos
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS pedidos;
CREATE TABLE pedidos (
  id INT NOT NULL,
  cliente_id INT NOT NULL,
  region VARCHAR(10) NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) DEFAULT 'pendiente',
  total DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este')
      COMMENT = 'server "srv_nodo04", table "pedidos"',
    PARTITION frag_B VALUES IN ('sur', 'oeste')
      COMMENT = 'server "srv_nodo05", table "pedidos"'
  );

-- --------------------------------------------------------------------------
-- 4.3 detalle_pedidos (sin region → dos tablas Spider simples + VIEW)
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS spider_detalle_nodo04;
CREATE TABLE spider_detalle_nodo04 (
  id INT NOT NULL,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE=SPIDER
  COMMENT = 'server "srv_nodo04", table "detalle_pedidos"';

DROP TABLE IF EXISTS spider_detalle_nodo05;
CREATE TABLE spider_detalle_nodo05 (
  id INT NOT NULL,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE=SPIDER
  COMMENT = 'server "srv_nodo05", table "detalle_pedidos"';

-- VIEW unificada de detalle_pedidos
DROP VIEW IF EXISTS detalle_pedidos;
CREATE VIEW detalle_pedidos AS
  SELECT * FROM spider_detalle_nodo04
  UNION ALL
  SELECT * FROM spider_detalle_nodo05;

-- ============================================================================
-- 5. TABLAS SPIDER — FRAGMENTACIÓN VERTICAL
-- ============================================================================

-- --------------------------------------------------------------------------
-- 5.1 v_productos_basico → nodo04 (columnas operacionales)
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS v_productos_basico;
CREATE TABLE v_productos_basico (
  id INT NOT NULL AUTO_INCREMENT,
  sku VARCHAR(50) NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  categoria VARCHAR(100),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sku (sku)
) ENGINE=SPIDER
  COMMENT = 'server "srv_nodo04", table "v_productos_basico"';

-- --------------------------------------------------------------------------
-- 5.2 v_productos_detalle → nodo05 (columnas de detalle TEXT)
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS v_productos_detalle;
CREATE TABLE v_productos_detalle (
  id INT NOT NULL,
  sku VARCHAR(50) NOT NULL,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(500),
  peso_kg DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE=SPIDER
  COMMENT = 'server "srv_nodo05", table "v_productos_detalle"';

-- --------------------------------------------------------------------------
-- 5.3 VIEW productos (JOIN distribuido)
-- --------------------------------------------------------------------------
DROP VIEW IF EXISTS productos;
CREATE VIEW productos AS
  SELECT
    b.id,
    b.sku,
    b.nombre,
    b.categoria,
    b.precio,
    b.stock,
    d.descripcion,
    d.ficha_tecnica,
    d.imagen_url,
    d.peso_kg,
    b.fecha_creacion
  FROM v_productos_basico b
  JOIN v_productos_detalle d ON b.id = d.id;

SET foreign_key_checks = 1;
