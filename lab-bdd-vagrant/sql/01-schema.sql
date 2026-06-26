-- =============================================================
-- Esquema del Laboratorio de Bases de Datos Distribuidas
-- Creado en la Fase 8. Diseñado para fragmentación futura.
-- =============================================================
CREATE DATABASE IF NOT EXISTS lab_bdd
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE lab_bdd;
-- -----------------------------------------------------------
-- CLIENTES: campo 'region' -> fragmentación horizontal (F13)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id          INT          AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE,
    telefono    VARCHAR(20),
    region      ENUM('norte','sur','este','oeste') NOT NULL,
    ciudad      VARCHAR(100),
    fecha_alta  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Fragmentación horizontal por region (Fase 13)';
-- -----------------------------------------------------------
-- PRODUCTOS: columnas básicas + detalle -> frag. vertical (F14)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS productos (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    sku             VARCHAR(50)   NOT NULL UNIQUE,
    nombre          VARCHAR(150)  NOT NULL,
    categoria       VARCHAR(50),
    precio          DECIMAL(10,2) NOT NULL,
    stock           INT           DEFAULT 0,
    -- Columnas de detalle (candidatas a nodo separado en Fase 14)
    descripcion     TEXT,
    ficha_tecnica   TEXT,
    imagen_url      VARCHAR(255),
    peso_kg         DECIMAL(6,3),
    fecha_creacion  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Fragmentación vertical: basico vs detalle (Fase 14)';
-- -----------------------------------------------------------
-- PEDIDOS: campo 'region' propio -> frag. horizontal (F13)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos (
    id           INT           AUTO_INCREMENT PRIMARY KEY,
    cliente_id   INT           NOT NULL,
    region       ENUM('norte','sur','este','oeste') NOT NULL,
    fecha_pedido DATETIME      DEFAULT CURRENT_TIMESTAMP,
    estado       ENUM('pendiente','procesado','enviado',
                      'entregado','cancelado') DEFAULT 'pendiente',
    total        DECIMAL(10,2),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Fragmentación horizontal por region (Fase 13)';
-- -----------------------------------------------------------
-- DETALLE_PEDIDOS: tabla de relación N:M
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS detalle_pedidos (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    pedido_id       INT           NOT NULL,
    producto_id     INT           NOT NULL,
    cantidad        INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) GENERATED ALWAYS AS
                    (cantidad * precio_unitario) STORED,
    FOREIGN KEY (pedido_id)   REFERENCES pedidos(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Detalle de lineas de pedido';
-- Confirmar la creación
SHOW TABLES;
