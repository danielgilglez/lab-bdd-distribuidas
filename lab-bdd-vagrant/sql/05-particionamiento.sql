-- =============================================================
-- Laboratorio de Particionamiento en MariaDB
-- Ejecutar en bdd-nodo01 (maestro) → se replica a nodo02/nodo03
-- =============================================================

-- 1. Esquema lab_particiones
CREATE SCHEMA IF NOT EXISTS lab_particiones
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci
COMMENT 'Demostracion de particionamiento nativos MARIADB';

USE lab_particiones;

-- 2. clientes_list4 — 4 particiones por LIST COLUMNS
CREATE TABLE IF NOT EXISTS clientes_list4(
    id int NOT NULL auto_increment,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    region VARCHAR(10) NOT NULL,
    ciudad VARCHAR(100),
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    primary key (id,region)
) ENGINE=innodb
COMMENT='Demo list 4 columnas (4 particiones)'
PARTITION BY LIST COLUMNS(region)(
    PARTITION p_norte VALUES IN ('norte'),
    PARTITION p_sur VALUES IN ('sur'),
    PARTITION p_este VALUES IN ('este'),
    PARTITION p_oeste VALUES IN ('oeste')
);

INSERT INTO clientes_list4 (nombre, apellido, email, telefono, region, ciudad) VALUES
('Juan', 'Pérez', 'juan.perez@email.com', '555-1001', 'norte', 'Monterrey'),
('María', 'García', 'maria.garcia@email.com', '555-1002', 'sur', 'Mérida'),
('Carlos', 'López', 'carlos.lopez@email.com', '555-1003', 'este', 'Cancún'),
('Ana', 'Martínez', 'ana.martinez@email.com', '555-1004', 'oeste', 'Guadalajara'),
('Luis', 'Hernández', 'luis.hernandez@email.com', '555-1005', 'norte', 'Chihuahua'),
('Sofía', 'Ramírez', 'sofia.ramirez@email.com', '555-1006', 'sur', 'Oaxaca'),
('Pedro', 'Sánchez', 'pedro.sanchez@email.com', '555-1007', 'este', 'Playa del Carmen'),
('Elena', 'Torres', 'elena.torres@email.com', '555-1008', 'oeste', 'Tijuana');

ANALYZE TABLE clientes_list4;

-- 3. clientes_list2 — 2 particiones por LIST COLUMNS
CREATE TABLE IF NOT EXISTS clientes_list2(
    id int NOT NULL auto_increment,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    region VARCHAR(10) NOT NULL,
    ciudad VARCHAR(100),
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
    primary key (id,region)
) ENGINE=innodb
COMMENT='Demo list 2 columnas (2 particiones)'
PARTITION BY LIST COLUMNS(region)(
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
);

INSERT INTO clientes_list2 (nombre, apellido, email, telefono, region, ciudad) VALUES
('Juan', 'Pérez', 'juan.perez@email.com', '555-1001', 'norte', 'Monterrey'),
('María', 'García', 'maria.garcia@email.com', '555-1002', 'sur', 'Mérida'),
('Carlos', 'López', 'carlos.lopez@email.com', '555-1003', 'este', 'Cancún'),
('Ana', 'Martínez', 'ana.martinez@email.com', '555-1004', 'oeste', 'Guadalajara');

-- 4. pedidos_part — 2 particiones por región (en lab_bdd)
USE lab_bdd;

CREATE TABLE IF NOT EXISTS lab_bdd.pedidos_part(
    id int NOT NULL auto_increment,
    cliente_id int NOT NULL,
    region VARCHAR(10) NOT NULL,
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente',
    total DECIMAL(10,2),
    primary key (id,region)
) ENGINE=innodb
COMMENT='Pedidos particionados por region (2 particiones)'
PARTITION BY LIST COLUMNS(region)(
    PARTITION p_norte_este VALUES IN ('norte', 'este'),
    PARTITION p_sur_oeste VALUES IN ('sur', 'oeste')
);

INSERT INTO lab_bdd.pedidos_part (id, cliente_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

ANALYZE TABLE lab_bdd.pedidos_part;

-- 5. pedidos_estado — 2 particiones por estado
CREATE TABLE IF NOT EXISTS lab_bdd.pedidos_estado(
    id int NOT NULL auto_increment,
    cliente_id int NOT NULL,
    region VARCHAR(10) NOT NULL,
    fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente',
    total DECIMAL(10,2),
    primary key (id,estado)
) ENGINE=innodb
COMMENT='Pedidos particionados por estado (2 particiones)'
PARTITION BY LIST COLUMNS(estado)(
    PARTITION p_activos VALUES IN ('pendiente', 'procesado', 'enviado'),
    PARTITION p_finalizados VALUES IN ('entregado', 'cancelado')
);

INSERT INTO lab_bdd.pedidos_estado (id, cliente_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

ANALYZE TABLE lab_bdd.pedidos_estado;

-- 6. pedidos en lab_particiones
USE lab_particiones;

CREATE TABLE lab_particiones.pedidos (
    id int NOT NULL auto_increment,
    client_id int NOT NULL,
    region varchar(10) NOT NULL,
    fecha_pedido datetime DEFAULT current_timestamp(),
    estado varchar(10) NOT NULL,
    total decimal(10,2),
    primary key (id,region)
) ENGINE=InnoDB
PARTITION BY LIST COLUMNS(region)(
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
);

INSERT INTO lab_particiones.pedidos (client_id, region, fecha_pedido, estado, total)
SELECT cliente_id, region, fecha_pedido, estado, total FROM lab_bdd.pedidos;

-- 7. pedidos_rangos — partición por rango de años
CREATE TABLE IF NOT EXISTS pedidos_rangos(
    id int NOT NULL auto_increment,
    cliente_id int NOT NULL,
    region varchar(10),
    fecha_pedido datetime DEFAULT current_timestamp,
    estado varchar(10),
    total decimal(10,2),
    PRIMARY KEY (id, fecha_pedido)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(fecha_pedido))(
    PARTITION p_anterior VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_2026 VALUES LESS THAN (2027),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

INSERT INTO pedidos_rangos (cliente_id, region, fecha_pedido, estado, total)
SELECT cliente_id, region, fecha_pedido, estado, total FROM lab_bdd.pedidos;

ANALYZE TABLE pedidos_rangos;
