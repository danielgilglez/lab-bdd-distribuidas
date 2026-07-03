-- ============================================================
-- FASE 12 — Particionamiento de Tablas en MariaDB
-- Basado en la ejecución real del usuario en bdd-nodo01
-- (Nombres de tablas y columnas según su implementación manual)
-- ============================================================
-- ESQUEMA: lab_particiones
-- TABLAS:  clientes_list4, clientes_list2, pedidos, pedidos_rangos,
--          accesos_hash, log_eventos_key, clientes_subpart
-- ============================================================

-- ============================================================
-- 1. CREAR ESQUEMA lab_particiones
-- ============================================================
DROP DATABASE IF EXISTS lab_particiones;
CREATE DATABASE IF NOT EXISTS lab_particiones
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lab_particiones;

-- ============================================================
-- 2. LIST COLUMNS — 4 particiones (una por región)
-- TABLA: clientes_list4
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes_list4 (
  id          INT           NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100)  NOT NULL,
  apellido    VARCHAR(100)  NOT NULL,
  email       VARCHAR(150),
  telefono    VARCHAR(20),
  region      VARCHAR(10)   NOT NULL,
  ciudad      VARCHAR(100),
  fecha_alta  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id, region)
) ENGINE=InnoDB
  COMMENT='Demo LIST COLUMNS — 4 particiones, una por región'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION p_norte VALUES IN ('norte'),
    PARTITION p_sur   VALUES IN ('sur'),
    PARTITION p_este  VALUES IN ('este'),
    PARTITION p_oeste VALUES IN ('oeste')
  );

INSERT INTO clientes_list4
  (id, nombre, apellido, email, telefono, region, ciudad, fecha_alta)
SELECT id, nombre, apellido, email, telefono, region, ciudad, fecha_alta
FROM lab_bdd.clientes;

ANALYZE TABLE clientes_list4;

-- ============================================================
-- 3. LIST COLUMNS — 2 particiones (frag_A / frag_B)
-- TABLAS: clientes_list2, pedidos
-- NOTA: pedidos usa client_id (la tabla lab_particiones, no lab_bdd)
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes_list2 (
  id          INT           NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100)  NOT NULL,
  apellido    VARCHAR(100)  NOT NULL,
  email       VARCHAR(150),
  telefono    VARCHAR(20),
  region      VARCHAR(10)   NOT NULL,
  ciudad      VARCHAR(100),
  fecha_alta  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id, region)
) ENGINE=InnoDB
  COMMENT='Demo LIST COLUMNS — 2 particiones (espeja frag_A y frag_B)'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
  );

INSERT INTO clientes_list2
  (id, nombre, apellido, email, telefono, region, ciudad, fecha_alta)
SELECT id, nombre, apellido, email, telefono, region, ciudad, fecha_alta
FROM lab_bdd.clientes;

-- pedidos: usa client_id (NO cliente_id); el SELECT mapea cliente_id→client_id
CREATE TABLE IF NOT EXISTS pedidos (
  id            INT           NOT NULL AUTO_INCREMENT,
  client_id     INT           NOT NULL,
  region        VARCHAR(10)   NOT NULL,
  fecha_pedido  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  estado        VARCHAR(20)   DEFAULT 'pendiente',
  total         DECIMAL(10,2),
  PRIMARY KEY (id, region)
) ENGINE=InnoDB
  COMMENT='Demo pedidos LIST COLUMNS — 2 particiones'
  PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
  );

INSERT INTO pedidos
  (id, client_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

ANALYZE TABLE clientes_list2;
ANALYZE TABLE pedidos;

-- Verificacion
SELECT 'clientes_list4' AS tabla, COUNT(*) AS total FROM clientes_list4
UNION ALL
SELECT 'clientes_list2', COUNT(*) FROM clientes_list2
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos;

-- ============================================================
-- 4. RANGE — particionamiento por año
-- TABLA: pedidos_rangos (nombre real usado por el usuario)
-- NOTA: esta tabla usa cliente_id (diferente de pedidos.client_id)
-- ============================================================
CREATE TABLE IF NOT EXISTS pedidos_rangos (
  id            INT           NOT NULL AUTO_INCREMENT,
  cliente_id    INT           NOT NULL,
  region        VARCHAR(10)   NOT NULL,
  fecha_pedido  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  estado        VARCHAR(20)   DEFAULT 'pendiente',
  total         DECIMAL(10,2),
  PRIMARY KEY (id, fecha_pedido)
) ENGINE=InnoDB
  COMMENT='Demo RANGE — partición por año de pedido'
  PARTITION BY RANGE (YEAR(fecha_pedido)) (
    PARTITION p_anterior VALUES LESS THAN (2024),
    PARTITION p_2024     VALUES LESS THAN (2025),
    PARTITION p_2025     VALUES LESS THAN (2026),
    PARTITION p_2026     VALUES LESS THAN (2027),
    PARTITION p_futuro   VALUES LESS THAN MAXVALUE
  );

INSERT INTO pedidos_rangos
  (id, cliente_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

-- Insertar pedidos históricos simulados
INSERT INTO pedidos_rangos (cliente_id, region, fecha_pedido, estado, total) VALUES
  ( 1, 'norte', '2023-03-15 10:00:00', 'entregado', 3500.00),
  ( 2, 'norte', '2023-06-20 14:30:00', 'entregado', 1200.00),
  ( 6, 'sur',   '2023-09-10 09:15:00', 'entregado', 4200.00),
  (11, 'este',  '2024-01-05 11:00:00', 'entregado',  950.00),
  (16, 'oeste', '2024-07-22 16:45:00', 'entregado', 2800.00);

ANALYZE TABLE pedidos_rangos;

-- Verificacion
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS limite_superior,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_rangos'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT COUNT(*) AS pedidos_2025,
       ROUND(SUM(total), 2) AS facturacion_2025
FROM pedidos_rangos
WHERE YEAR(fecha_pedido) = 2025;

-- ============================================================
-- 5. HASH — distribución uniforme por id
-- TABLA: accesos_hash
-- NOTA: accion VARCHAR(15), no ENUM (MariaDB no requiere ENUM)
-- ============================================================
CREATE TABLE IF NOT EXISTS accesos_hash (
  id          BIGINT        NOT NULL AUTO_INCREMENT,
  usuario_id  INT           NOT NULL,
  recurso     VARCHAR(200)  NOT NULL,
  accion      VARCHAR(15)   NOT NULL,
  ts          DATETIME      DEFAULT CURRENT_TIMESTAMP,
  ip_origen   VARCHAR(45),
  PRIMARY KEY (id)
) ENGINE=InnoDB
  COMMENT='Log de accesos — HASH por id'
  PARTITION BY HASH (id) PARTITIONS 4;

-- 105 registros (21 clientes × 5 accesos)
INSERT INTO accesos_hash (usuario_id, recurso, accion, ip_origen)
SELECT
  c.id AS usuario_id,
  CONCAT('/api/recurso/', n.n, '/', c.id) AS recurso,
  ELT(((c.id + n.n - 1) % 4) + 1, 'SELECT','INSERT','UPDATE','DELETE') AS accion,
  CONCAT('192.168.56.', 100 + (c.id % 7)) AS ip_origen
FROM lab_bdd.clientes c
CROSS JOIN (
  SELECT 1 AS n UNION SELECT 2 UNION SELECT 3
  UNION SELECT 4 UNION SELECT 5
) n;

ANALYZE TABLE accesos_hash;

SELECT PARTITION_NAME AS particion,
       TABLE_ROWS AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'accesos_hash'
ORDER BY PARTITION_NAME;

-- ============================================================
-- 6. KEY — hashing interno sobre columna de texto
-- TABLA: log_eventos_key
-- IMPORTANTE: nivel VARCHAR(15), NO ENUM (ENUM causa ERROR 1659
-- con KEY partitioning en MariaDB)
-- ============================================================
CREATE TABLE IF NOT EXISTS log_eventos_key (
  id          BIGINT        NOT NULL AUTO_INCREMENT,
  nivel       VARCHAR(15)   NOT NULL,
  componente  VARCHAR(50)   NOT NULL,
  mensaje     TEXT,
  ts          DATETIME      DEFAULT CURRENT_TIMESTAMP,
  servidor    VARCHAR(30),
  PRIMARY KEY (id, componente)
) ENGINE=InnoDB
  COMMENT='Log de eventos — KEY sobre columna de texto'
  PARTITION BY KEY (componente) PARTITIONS 4;

INSERT INTO log_eventos_key (nivel, componente, mensaje, servidor) VALUES
  ('INFO',  'replicacion', 'Binlog position actualizada',                  'bdd-nodo01'),
  ('INFO',  'replicacion', 'Replica IO thread activo',                     'bdd-nodo02'),
  ('WARN',  'conexiones',  'Pool de conexiones al 80%',                    'bdd-nodo01'),
  ('ERROR', 'particion',   'No se encontró partición para valor recibido', 'bdd-nodo04'),
  ('INFO',  'spider',      'Consulta ejecutada en 2 nodos remotos',        'bdd-nodo06'),
  ('DEBUG', 'consultas',   'Plan de ejecución seleccionado',               'bdd-nodo01'),
  ('INFO',  'respaldos',   'mysqldump completado exitosamente',            'bdd-nodo01'),
  ('FATAL', 'replicacion', 'Replica SQL thread detenido por error',        'bdd-nodo02'),
  ('INFO',  'conexiones',  'Nueva conexión desde 192.168.56.107',          'bdd-nodo06'),
  ('WARN',  'consultas',   'Slow query detectada: 3.2 segundos',           'bdd-nodo01'),
  ('INFO',  'particion',   'ANALYZE PARTITION completado',                 'bdd-nodo04'),
  ('ERROR', 'spider',      'Timeout en nodo remoto 192.168.56.105',        'bdd-nodo06');

ANALYZE TABLE log_eventos_key;

SELECT PARTITION_NAME AS particion,
       TABLE_ROWS AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'log_eventos_key'
ORDER BY PARTITION_NAME;

-- ============================================================
-- 7. PODA DE PARTICIONES — verificación con EXPLAIN
-- ============================================================
-- LIST: poda activa con predicado de igualdad
EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region = 'norte';

EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4;

EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region IN ('norte', 'este');

-- RANGE: poda temporal
EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos
WHERE YEAR(fecha_pedido) = 2025;

EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos
WHERE fecha_pedido BETWEEN '2024-01-01' AND '2025-12-31';

EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_rangos;

-- HASH: NO poda con predicados de negocio
EXPLAIN SELECT COUNT(*)
FROM accesos_hash
WHERE usuario_id = 1;

-- HASH: poda SOLO con el atributo de hash exacto (id)
EXPLAIN SELECT * FROM accesos_hash WHERE id = 42;

-- ============================================================
-- 8. AUDITORÍA — INFORMATION_SCHEMA.PARTITIONS
-- ============================================================
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

SELECT TABLE_NAME AS tabla,
       COUNT(PARTITION_NAME) AS num_particiones,
       SUM(TABLE_ROWS) AS filas_totales_est,
       ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024.0, 2) AS total_KB
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- ============================================================
-- 9. MANTENIMIENTO DE PARTICIONES
-- ============================================================

-- 9a. ADD PARTITION — agregar 'centro' a clientes_list4
ALTER TABLE clientes_list4
ADD PARTITION (PARTITION p_centro VALUES IN ('centro'));

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list4'
ORDER BY PARTITION_ORDINAL_POSITION;

INSERT INTO clientes_list4 (id, nombre, apellido, email, region, ciudad)
VALUES (21, 'Gabriela', 'Núñez', 'gabriela.nunez@lab.test', 'centro', 'CDMX');

SELECT region, COUNT(*) AS clientes
FROM clientes_list4
GROUP BY region
ORDER BY region;

-- 9b. REORGANIZE PARTITION — dividir frag_A en p_norte y p_este
ALTER TABLE clientes_list2
REORGANIZE PARTITION frag_A INTO (
  PARTITION p_norte VALUES IN ('norte'),
  PARTITION p_este  VALUES IN ('este')
);

ANALYZE TABLE clientes_list2;

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list2'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT COUNT(*) AS total_clientes_list2 FROM clientes_list2;

-- 9c. TRUNCATE PARTITION — vaciar p_anterior (años < 2024)
SELECT YEAR(fecha_pedido) AS anyo, COUNT(*) AS pedidos
FROM pedidos_rangos
GROUP BY anyo ORDER BY anyo;

ALTER TABLE pedidos_rangos TRUNCATE PARTITION p_anterior;

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_rangos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- 9d. REORGANIZE — partir p_futuro en p_2027 + p_futuro
ALTER TABLE pedidos_rangos
REORGANIZE PARTITION p_futuro INTO (
  PARTITION p_2027   VALUES LESS THAN (2028),
  PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

SELECT PARTITION_NAME, PARTITION_DESCRIPTION
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_rangos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- 9e. ANALYZE PARTITION
ALTER TABLE clientes_list4 ANALYZE PARTITION ALL;

-- 9f. DROP PARTITION — eliminar p_centro
SELECT COUNT(*) AS filas_a_eliminar
FROM clientes_list4 WHERE region = 'centro';

ALTER TABLE clientes_list4 DROP PARTITION p_centro;

SELECT COUNT(*) AS total_list4 FROM clientes_list4;

-- ============================================================
-- 10. SUBPARTICIONAMIENTO — LIST COLUMNS + HASH
-- TABLA: clientes_subpart
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes_subpart (
  id          INT           NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100)  NOT NULL,
  apellido    VARCHAR(100)  NOT NULL,
  region      VARCHAR(15)   NOT NULL,
  ciudad      VARCHAR(100),
  PRIMARY KEY (id, region)
) ENGINE=InnoDB
  COMMENT='Demo subparticionamiento LIST COLUMNS + HASH — 4×2 segmentos'
  PARTITION BY LIST COLUMNS (region)
  SUBPARTITION BY HASH (id) SUBPARTITIONS 2
  (
    PARTITION p_norte VALUES IN ('norte'),
    PARTITION p_sur   VALUES IN ('sur'),
    PARTITION p_este  VALUES IN ('este'),
    PARTITION p_oeste VALUES IN ('oeste')
  );

INSERT INTO clientes_subpart (id, nombre, apellido, region, ciudad)
SELECT id, nombre, apellido, region, ciudad
FROM lab_bdd.clientes;

ANALYZE TABLE clientes_subpart;

SELECT PARTITION_NAME,
       SUBPARTITION_NAME,
       PARTITION_DESCRIPTION AS region,
       TABLE_ROWS AS filas_est
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_subpart'
ORDER BY PARTITION_ORDINAL_POSITION, SUBPARTITION_ORDINAL_POSITION;

-- ============================================================
-- 11. DEMO FK — incompatibilidad con particionamiento
-- (Los errores son el resultado esperado)
-- ============================================================

-- CASO 1: Agregar FK a tabla ya particionada → ERROR 1217/1506
ALTER TABLE lab_particiones.pedidos
ADD CONSTRAINT fk_pedidos_cliente
FOREIGN KEY (client_id)
REFERENCES lab_particiones.clientes_list2(id);

-- CASO 2: Particionar tabla que ya tiene FK → ERROR
ALTER TABLE lab_bdd.pedidos
PARTITION BY LIST COLUMNS (region) (
  PARTITION frag_A VALUES IN ('norte', 'este'),
  PARTITION frag_B VALUES IN ('sur', 'oeste')
);
