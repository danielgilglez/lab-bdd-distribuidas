-- ============================================================================
-- Fase 12 — Particionamiento de Tablas en MariaDB
-- Laboratorio de Bases de Datos Distribuidas
-- Ejecutar en bdd-nodo01 (maestro) → se replica a nodo02/nodo03
-- ============================================================================

-- ============================================================================
-- 1. CREACIÓN DEL ESQUEMA
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS lab_particiones
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci
COMMENT 'Demostración de particionamiento nativo MariaDB — Fase 12';

USE lab_particiones;

-- ============================================================================
-- 2. LIST COLUMNS — 4 particiones (una por región)
-- ============================================================================
CREATE TABLE IF NOT EXISTS clientes_list4 (
    id          INT             NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100)    NOT NULL,
    apellido    VARCHAR(100)    NOT NULL,
    email       VARCHAR(150),
    telefono    VARCHAR(20),
    region      VARCHAR(10)     NOT NULL,
    ciudad      VARCHAR(100),
    fecha_alta  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, region)
) ENGINE=InnoDB
COMMENT='Demo LIST COLUMNS — 4 particiones, una por región'
PARTITION BY LIST COLUMNS (region) (
    PARTITION p_norte VALUES IN ('norte'),
    PARTITION p_sur   VALUES IN ('sur'),
    PARTITION p_este  VALUES IN ('este'),
    PARTITION p_oeste VALUES IN ('oeste')
);

INSERT INTO clientes_list4 (id, nombre, apellido, email, telefono, region, ciudad, fecha_alta)
SELECT id, nombre, apellido, email, telefono, region, ciudad, fecha_alta
FROM lab_bdd.clientes;

ANALYZE TABLE clientes_list4;

SELECT 'clientes_list4 — distribución por partición' AS '';
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS region_cubierta,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'clientes_list4'
ORDER BY PARTITION_ORDINAL_POSITION;

-- ============================================================================
-- 3. LIST COLUMNS — 2 particiones (frag_A / frag_B como el DDD)
-- ============================================================================
CREATE TABLE IF NOT EXISTS clientes_list2 (
    id          INT             NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100)    NOT NULL,
    apellido    VARCHAR(100)    NOT NULL,
    email       VARCHAR(150),
    telefono    VARCHAR(20),
    region      VARCHAR(10)     NOT NULL,
    ciudad      VARCHAR(100),
    fecha_alta  DATETIME        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, region)
) ENGINE=InnoDB
COMMENT='Demo LIST COLUMNS — 2 particiones (espeja frag_A y frag_B del DDD)'
PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
);

INSERT INTO clientes_list2 (id, nombre, apellido, email, telefono, region, ciudad, fecha_alta)
SELECT id, nombre, apellido, email, telefono, region, ciudad, fecha_alta
FROM lab_bdd.clientes;

ANALYZE TABLE clientes_list2;

-- ============================================================================
-- 4. pedidos_list2 — LIST COLUMNS, 2 particiones
-- ============================================================================
CREATE TABLE IF NOT EXISTS pedidos_list2 (
    id           INT             NOT NULL AUTO_INCREMENT,
    cliente_id   INT             NOT NULL,
    region       VARCHAR(10)     NOT NULL,
    fecha_pedido DATETIME        DEFAULT CURRENT_TIMESTAMP,
    estado       ENUM('pendiente','procesado','enviado','entregado','cancelado') DEFAULT 'pendiente',
    total        DECIMAL(10,2),
    PRIMARY KEY (id, region)
) ENGINE=InnoDB
COMMENT='Demo pedidos LIST COLUMNS — 2 particiones (espeja frag_A y frag_B del DDD)'
PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur', 'oeste')
);

INSERT INTO pedidos_list2 (id, cliente_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

ANALYZE TABLE pedidos_list2;

-- ============================================================================
-- 5. RANGE — particionamiento por año
-- ============================================================================
CREATE TABLE IF NOT EXISTS pedidos_range (
    id           INT             NOT NULL AUTO_INCREMENT,
    cliente_id   INT             NOT NULL,
    region       VARCHAR(10)     NOT NULL,
    fecha_pedido DATETIME        DEFAULT CURRENT_TIMESTAMP,
    estado       VARCHAR(10),
    total        DECIMAL(10,2),
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

INSERT INTO pedidos_range (id, cliente_id, region, fecha_pedido, estado, total)
SELECT id, cliente_id, region, fecha_pedido, estado, total
FROM lab_bdd.pedidos;

INSERT INTO pedidos_range (cliente_id, region, fecha_pedido, estado, total) VALUES
( 1, 'norte', '2023-03-15 10:00:00', 'entregado', 3500.00),
( 2, 'norte', '2023-06-20 14:30:00', 'entregado', 1200.00),
( 6, 'sur',   '2023-09-10 09:15:00', 'entregado', 4200.00),
(11, 'este',  '2024-01-05 11:00:00', 'entregado',  950.00),
(16, 'oeste', '2024-07-22 16:45:00', 'entregado', 2800.00);

ANALYZE TABLE pedidos_range;

SELECT 'pedidos_range — distribución por partición' AS '';
SELECT PARTITION_NAME AS particion,
       PARTITION_DESCRIPTION AS limite_superior,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'pedidos_range'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT COUNT(*) AS pedidos_2025,
       ROUND(SUM(total), 2) AS facturacion_2025
FROM pedidos_range
WHERE YEAR(fecha_pedido) = 2025;

-- ============================================================================
-- 6. HASH — distribución uniforme sobre columna numérica
-- ============================================================================
CREATE TABLE IF NOT EXISTS accesos_hash (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    usuario_id  INT          NOT NULL,
    recurso     VARCHAR(200) NOT NULL,
    accion      VARCHAR(15)  NOT NULL,
    ts          DATETIME     DEFAULT CURRENT_TIMESTAMP,
    ip_origen   VARCHAR(45),
    PRIMARY KEY (id)
) ENGINE=InnoDB
COMMENT='Log de accesos — demostración HASH por id'
PARTITION BY HASH (id) PARTITIONS 4;

INSERT INTO accesos_hash (usuario_id, recurso, accion, ip_origen)
SELECT
    c.id                                        AS usuario_id,
    CONCAT('/api/recurso/', n.n, '/', c.id)    AS recurso,
    ELT(((c.id + n.n - 1) % 4) + 1,
        'SELECT','INSERT','UPDATE','DELETE')    AS accion,
    CONCAT('192.168.56.', 100 + (c.id % 7))   AS ip_origen
FROM lab_bdd.clientes c
CROSS JOIN (
    SELECT 1 AS n UNION SELECT 2 UNION SELECT 3
    UNION SELECT 4 UNION SELECT 5
) n;

ANALYZE TABLE accesos_hash;

SELECT 'accesos_hash — distribución por partición' AS '';
SELECT PARTITION_NAME AS particion,
       TABLE_ROWS     AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'accesos_hash'
ORDER BY PARTITION_NAME;

-- ============================================================================
-- 7. KEY — hashing interno sobre columna de texto
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_eventos_key (
    id          BIGINT        NOT NULL AUTO_INCREMENT,
    nivel       VARCHAR(15)   NOT NULL,
    componente  VARCHAR(50)   NOT NULL,
    mensaje     TEXT,
    ts          DATETIME      DEFAULT CURRENT_TIMESTAMP,
    servidor    VARCHAR(30),
    PRIMARY KEY (id, componente)
) ENGINE=InnoDB
COMMENT='Log de eventos — demostración KEY sobre columna de texto'
PARTITION BY KEY (componente) PARTITIONS 4;

INSERT INTO log_eventos_key (nivel, componente, mensaje, servidor) VALUES
('INFO',  'replicacion', 'Binlog position actualizada',              'bdd-nodo01'),
('INFO',  'replicacion', 'Replica IO thread activo',                 'bdd-nodo02'),
('WARN',  'conexiones',  'Pool de conexiones al 80%',                'bdd-nodo01'),
('ERROR', 'particion',   'No se encontró partición para valor recibido', 'bdd-nodo04'),
('INFO',  'spider',      'Consulta ejecutada en 2 nodos remotos',    'bdd-nodo06'),
('DEBUG', 'consultas',   'Plan de ejecución seleccionado',           'bdd-nodo01'),
('INFO',  'respaldos',   'mysqldump completado exitosamente',        'bdd-nodo01'),
('FATAL', 'replicacion', 'Replica SQL thread detenido por error',    'bdd-nodo02'),
('INFO',  'conexiones',  'Nueva conexión desde 192.168.56.107',      'bdd-nodo06'),
('WARN',  'consultas',   'Slow query detectada: 3.2 segundos',       'bdd-nodo01'),
('INFO',  'particion',   'ANALYZE PARTITION completado',             'bdd-nodo04'),
('ERROR', 'spider',      'Timeout en nodo remoto 192.168.56.105',    'bdd-nodo06');

ANALYZE TABLE log_eventos_key;

SELECT 'log_eventos_key — distribución por partición' AS '';
SELECT PARTITION_NAME AS particion,
       TABLE_ROWS     AS filas_estimadas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'log_eventos_key'
ORDER BY PARTITION_NAME;

-- ============================================================================
-- 8. VERIFICACIÓN DE PODA DE PARTICIONES (EXPLAIN)
-- ============================================================================
SELECT '=== EXPERIMENTO A: LIST — poda activa con predicado de igualdad ===' AS '';

EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region = 'norte';

EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4;

EXPLAIN SELECT id, nombre, ciudad
FROM clientes_list4
WHERE region IN ('norte', 'este');

SELECT '=== EXPERIMENTO B: RANGE — poda temporal ===' AS '';

EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_range
WHERE YEAR(fecha_pedido) = 2025;

EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_range
WHERE fecha_pedido BETWEEN '2024-01-01' AND '2025-12-31';

EXPLAIN SELECT COUNT(*), SUM(total)
FROM pedidos_range;

SELECT '=== EXPERIMENTO C: HASH — sin poda con predicados de negocio ===' AS '';

EXPLAIN SELECT COUNT(*)
FROM accesos_hash
WHERE usuario_id = 1;

EXPLAIN SELECT * FROM accesos_hash WHERE id = 42;

SELECT '=== Conteo exacto por partición ===' AS '';
SELECT 'p_norte (list4)'  AS particion, COUNT(*) AS filas
FROM clientes_list4 WHERE region = 'norte' UNION ALL
SELECT 'p_sur (list4)',    COUNT(*) FROM clientes_list4 WHERE region = 'sur'  UNION ALL
SELECT 'p_este (list4)',   COUNT(*) FROM clientes_list4 WHERE region = 'este' UNION ALL
SELECT 'p_oeste (list4)',  COUNT(*) FROM clientes_list4 WHERE region = 'oeste' UNION ALL
SELECT 'frag_A (list2)',   COUNT(*) FROM clientes_list2 WHERE region IN ('norte','este') UNION ALL
SELECT 'frag_B (list2)',   COUNT(*) FROM clientes_list2 WHERE region IN ('sur','oeste');

-- ============================================================================
-- 9. AUDITORÍA CON INFORMATION_SCHEMA.PARTITIONS
-- ============================================================================
SELECT '=== Auditoría completa de particiones ===' AS '';
SELECT
    TABLE_NAME                         AS tabla,
    PARTITION_NAME                     AS particion,
    PARTITION_METHOD                   AS tipo,
    PARTITION_EXPRESSION               AS expresion,
    PARTITION_DESCRIPTION              AS definicion,
    TABLE_ROWS                         AS filas_est,
    ROUND(DATA_LENGTH / 1024.0, 2)     AS datos_KB,
    ROUND(INDEX_LENGTH / 1024.0, 2)    AS indices_KB
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;

SELECT '=== Resumen por tabla ===' AS '';
SELECT
    TABLE_NAME                                                      AS tabla,
    COUNT(PARTITION_NAME)                                           AS num_particiones,
    SUM(TABLE_ROWS)                                                 AS filas_totales_est,
    ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024.0, 2)              AS total_KB
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- ============================================================================
-- 10. MANTENIMIENTO DE PARTICIONES
-- ============================================================================
SELECT '=== OPERACIÓN 1: ADD PARTITION (clientes_list4 + centro) ===' AS '';

ALTER TABLE clientes_list4
MODIFY COLUMN region ENUM('norte','sur','este','oeste','centro') NOT NULL;

ALTER TABLE clientes_list4
ADD PARTITION (PARTITION p_centro VALUES IN ('centro'));

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'clientes_list4'
ORDER BY PARTITION_ORDINAL_POSITION;

INSERT INTO clientes_list4 (id, nombre, apellido, email, region, ciudad)
VALUES (21, 'Gabriela', 'Núñez', 'gabriela.nunez@lab.test', 'centro', 'CDMX');

SELECT region, COUNT(*) AS clientes FROM clientes_list4 GROUP BY region ORDER BY region;

SELECT '=== OPERACIÓN 2: REORGANIZE PARTITION (clientes_list2) ===' AS '';

ALTER TABLE clientes_list2
REORGANIZE PARTITION frag_A INTO (
    PARTITION p_norte VALUES IN ('norte'),
    PARTITION p_este  VALUES IN ('este')
);

ANALYZE TABLE clientes_list2;

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'clientes_list2'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT COUNT(*) AS total_clientes_list2 FROM clientes_list2;

SELECT '=== OPERACIÓN 3: TRUNCATE PARTITION (pedidos_range) ===' AS '';

SELECT YEAR(fecha_pedido) AS anyo, COUNT(*) AS pedidos
FROM pedidos_range
GROUP BY anyo ORDER BY anyo;

ALTER TABLE pedidos_range TRUNCATE PARTITION p_anterior;

ANALYZE TABLE pedidos_range;

SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'pedidos_range'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== OPERACIÓN 4: REORGANIZE para agregar p_2027 ===' AS '';

ALTER TABLE pedidos_range
REORGANIZE PARTITION p_futuro INTO (
    PARTITION p_2027   VALUES LESS THAN (2028),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

SELECT PARTITION_NAME, PARTITION_DESCRIPTION
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'pedidos_range'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== OPERACIÓN 5: ANALYZE PARTITION ===' AS '';

ALTER TABLE clientes_list4 ANALYZE PARTITION ALL;
ALTER TABLE pedidos_range ANALYZE PARTITION p_2024, p_2025, p_2026;

SELECT '=== OPERACIÓN 6: DROP PARTITION (p_centro) ===' AS '';

SELECT COUNT(*) AS filas_a_eliminar FROM clientes_list4 WHERE region = 'centro';

ALTER TABLE clientes_list4 DROP PARTITION p_centro;

SELECT COUNT(*) AS total_list4 FROM clientes_list4;

-- ============================================================================
-- 11. SUBPARTICIONAMIENTO (LIST + HASH)
-- ============================================================================
CREATE TABLE IF NOT EXISTS clientes_subpart (
    id          INT             NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100)    NOT NULL,
    apellido    VARCHAR(100)    NOT NULL,
    region      VARCHAR(15)     NOT NULL,
    ciudad      VARCHAR(100),
    PRIMARY KEY (id, region)
) ENGINE=InnoDB
COMMENT='Demo subparticionamiento LIST COLUMNS + HASH — 4x2 segmentos'
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

SELECT 'clientes_subpart — 8 segmentos (4 particiones × 2 subparticiones)' AS '';
SELECT PARTITION_NAME,
       SUBPARTITION_NAME,
       PARTITION_DESCRIPTION AS region,
       TABLE_ROWS AS filas_est
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME   = 'clientes_subpart'
ORDER BY PARTITION_ORDINAL_POSITION, SUBPARTITION_ORDINAL_POSITION;

-- ============================================================================
-- 12. DEMOSTRACIÓN DE INCOMPATIBILIDAD CON FK
-- ============================================================================
-- Los siguientes comandos fallarán INTENCIONALMENTE (ERROR).
-- Son parte del aprendizaje: MariaDB no permite FK en tablas particionadas.

SELECT '=== CASO 1: agregar FK a tabla particionada (fallará) ===' AS '';

ALTER TABLE lab_particiones.pedidos_list2
    ADD CONSTRAINT fk_pedidos_list2_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES lab_particiones.clientes_list2(id);

SELECT '=== CASO 2: particionar tabla con FK (fallará) ===' AS '';

ALTER TABLE lab_bdd.pedidos
    PARTITION BY LIST COLUMNS (region) (
    PARTITION frag_A VALUES IN ('norte', 'este'),
    PARTITION frag_B VALUES IN ('sur',   'oeste')
);

-- ============================================================================
-- 13. LISTADO FINAL DE TABLAS
-- ============================================================================
SELECT '=== Tablas en lab_particiones ===' AS '';
SHOW TABLES;

SELECT '=== Fase 12 completada exitosamente ===' AS '';
