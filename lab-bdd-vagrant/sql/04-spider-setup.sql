INSTALL SONAME 'ha_spider';

CREATE DATABASE IF NOT EXISTS lab_bdd;

CREATE TABLE IF NOT EXISTS lab_bdd.clientes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  telefono VARCHAR(20),
  region ENUM('norte','sur','este','oeste') NOT NULL,
  ciudad VARCHAR(100),
  fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lab_bdd.productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  categoria VARCHAR(50),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(255),
  peso_kg DECIMAL(6,3),
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lab_bdd.pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT NOT NULL,
  region ENUM('norte','sur','este','oeste') NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('pendiente','procesado','enviado','entregado','cancelado') DEFAULT 'pendiente',
  total DECIMAL(10,2)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lab_bdd.detalle_pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
) ENGINE=InnoDB;

DROP TABLE IF EXISTS lab_bdd.clientes;
CREATE TABLE lab_bdd.clientes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  telefono VARCHAR(20),
  region ENUM('norte','sur','este','oeste') NOT NULL,
  ciudad VARCHAR(100),
  fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=SPIDER COMMENT='wrapper "mysql", table "clientes"
  srv "shard_a", srv "shard_b"
  partition by list (region)
  (partition shard_a values in ("norte","este") comment "host \'192.168.56.104\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'",
   partition shard_b values in ("sur","oeste") comment "host \'192.168.56.105\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'")
';

DROP TABLE IF EXISTS lab_bdd.pedidos;
CREATE TABLE lab_bdd.pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT NOT NULL,
  region ENUM('norte','sur','este','oeste') NOT NULL,
  fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('pendiente','procesado','enviado','entregado','cancelado') DEFAULT 'pendiente',
  total DECIMAL(10,2)
) ENGINE=SPIDER COMMENT='wrapper "mysql", table "pedidos"
  srv "shard_a", srv "shard_b"
  partition by list (region)
  (partition shard_a values in ("norte","este") comment "host \'192.168.56.104\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'",
   partition shard_b values in ("sur","oeste") comment "host \'192.168.56.105\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'")
';

DROP TABLE IF EXISTS lab_bdd.detalle_pedidos;
CREATE TABLE lab_bdd.detalle_pedidos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
) ENGINE=SPIDER COMMENT='wrapper "mysql", table "detalle_pedidos"
  srv "shard_a", srv "shard_b"
  partition by list (region)
  (partition shard_a values in ("norte","este") comment "host \'192.168.56.104\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'",
   partition shard_b values in ("sur","oeste") comment "host \'192.168.56.105\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'")
';

DROP TABLE IF EXISTS lab_bdd.productos_basico;
CREATE TABLE lab_bdd.productos_basico (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  categoria VARCHAR(50),
  precio DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=SPIDER COMMENT='wrapper "mysql", table "productos"
  srv "shard_a"
  comment "host \'192.168.56.104\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'"
';

DROP TABLE IF EXISTS lab_bdd.productos_detalle;
CREATE TABLE lab_bdd.productos_detalle (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(255),
  peso_kg DECIMAL(6,3)
) ENGINE=SPIDER COMMENT='wrapper "mysql", table "productos"
  srv "shard_b"
  comment "host \'192.168.56.105\', port 3306, user \'lab_admin\', password \'LabAdmin_2025!\'"
';
