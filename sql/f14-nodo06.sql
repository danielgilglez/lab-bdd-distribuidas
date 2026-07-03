CREATE SERVER IF NOT EXISTS srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.104', PORT 3306, DATABASE 'lab_bdd', USER 'spider_user', PASSWORD 'Spider_2025!');

CREATE SERVER IF NOT EXISTS srv_nodo05
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.105', PORT 3306, DATABASE 'lab_bdd', USER 'spider_user', PASSWORD 'Spider_2025!');

CREATE DATABASE IF NOT EXISTS lab_bdd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lab_bdd;

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
) ENGINE=SPIDER
PARTITION BY LIST COLUMNS (region) (
  PARTITION frag_A VALUES IN ('norte','este') COMMENT = 'server "srv_nodo04", table "clientes"',
  PARTITION frag_B VALUES IN ('sur','oeste') COMMENT = 'server "srv_nodo05", table "clientes"'
);

CREATE TABLE IF NOT EXISTS pedidos (
  id INT NOT NULL AUTO_INCREMENT,
  cliente_id INT NOT NULL,
  region VARCHAR(10) NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) DEFAULT 'pendiente',
  total DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
PARTITION BY LIST COLUMNS (region) (
  PARTITION frag_A VALUES IN ('norte','este') COMMENT = 'server "srv_nodo04", table "pedidos"',
  PARTITION frag_B VALUES IN ('sur','oeste') COMMENT = 'server "srv_nodo05", table "pedidos"'
);

CREATE TABLE IF NOT EXISTS spider_detalle_nodo04 (
  id INT NOT NULL AUTO_INCREMENT,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE=SPIDER COMMENT = 'server "srv_nodo04", table "detalle_pedidos"';

CREATE TABLE IF NOT EXISTS spider_detalle_nodo05 (
  id INT NOT NULL AUTO_INCREMENT,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2),
  PRIMARY KEY (id)
) ENGINE=SPIDER COMMENT = 'server "srv_nodo05", table "detalle_pedidos"';

CREATE OR REPLACE VIEW detalle_pedidos AS
  SELECT * FROM spider_detalle_nodo04
  UNION ALL
  SELECT * FROM spider_detalle_nodo05;

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
) ENGINE=SPIDER COMMENT = 'server "srv_nodo04", table "v_productos_basico"';

CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id INT NOT NULL,
  sku VARCHAR(50) NOT NULL,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(500),
  peso_kg DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE=SPIDER COMMENT = 'server "srv_nodo05", table "v_productos_detalle"';

CREATE OR REPLACE VIEW productos AS
  SELECT b.id, b.sku, b.nombre, b.categoria, b.precio, b.stock,
         d.descripcion, d.ficha_tecnica, d.imagen_url, d.peso_kg,
         b.fecha_creacion
  FROM v_productos_basico b
  JOIN v_productos_detalle d ON b.id = d.id;

SELECT 'clientes (Spider PARTITION)' AS fuente, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'pedidos (Spider PARTITION)', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*) FROM detalle_pedidos
UNION ALL
SELECT 'v_productos_basico (Spider nodo04)', COUNT(*) FROM v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider nodo05)', COUNT(*) FROM v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN)', COUNT(*) FROM productos;
