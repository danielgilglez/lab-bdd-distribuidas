INSTALL SONAME 'ha_spider';

SET foreign_key_checks = 0;

DROP SERVER IF EXISTS shard_a;
CREATE SERVER shard_a
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.104', PORT 3306, USER 'lab_admin', PASSWORD 'LabAdmin_2025!');

DROP SERVER IF EXISTS shard_b;
CREATE SERVER shard_b
FOREIGN DATA WRAPPER mysql
OPTIONS (HOST '192.168.56.105', PORT 3306, USER 'lab_admin', PASSWORD 'LabAdmin_2025!');

CREATE DATABASE IF NOT EXISTS lab_bdd;

DROP TABLE IF EXISTS lab_bdd.detalle_pedidos;
DROP TABLE IF EXISTS lab_bdd.pedidos;
DROP TABLE IF EXISTS lab_bdd.clientes;
DROP TABLE IF EXISTS lab_bdd.productos_basico;
DROP TABLE IF EXISTS lab_bdd.productos_detalle;
DROP TABLE IF EXISTS lab_bdd.productos;

CREATE TABLE lab_bdd.clientes (
  id INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150),
  telefono VARCHAR(20),
  region VARCHAR(10) NOT NULL,
  ciudad VARCHAR(100),
  fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "clientes"'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION shard_a VALUES IN ('norte','este') COMMENT 'srv "shard_a"',
    PARTITION shard_b VALUES IN ('sur','oeste') COMMENT 'srv "shard_b"'
  );

CREATE TABLE lab_bdd.pedidos (
  id INT NOT NULL,
  cliente_id INT NOT NULL,
  region VARCHAR(10) NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) DEFAULT 'pendiente',
  total DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "pedidos"'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION shard_a VALUES IN ('norte','este') COMMENT 'srv "shard_a"',
    PARTITION shard_b VALUES IN ('sur','oeste') COMMENT 'srv "shard_b"'
  );

CREATE TABLE lab_bdd.detalle_pedidos (
  id INT NOT NULL,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
  PRIMARY KEY (id, pedido_id)
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "detalle_pedidos"'
  PARTITION BY LIST (pedido_id MOD 2) (
    PARTITION shard_a VALUES IN (0) COMMENT 'srv "shard_a"',
    PARTITION shard_b VALUES IN (1) COMMENT 'srv "shard_b"'
  );

CREATE TABLE lab_bdd.productos_basico (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  categoria VARCHAR(50),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "productos", srv "shard_a"';

CREATE TABLE lab_bdd.productos_detalle (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(255),
  peso_kg DECIMAL(6,3)
) ENGINE=SPIDER
  COMMENT='wrapper "mysql", table "productos", srv "shard_b"';

SET foreign_key_checks = 1;
