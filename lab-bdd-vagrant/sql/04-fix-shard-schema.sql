-- ============================================================================
-- Fase 13 — Adaptación de esquema para nodos shard
-- Ejecutar en bdd-nodo04 (Shard A) y bdd-nodo05 (Shard B)
--
-- Propósito:
-- 1. Eliminar FK constraints (la integridad se garantiza por co-localización)
-- 2. Cambiar ENUM a VARCHAR para compatibilidad con Spider (Fase 14)
-- 3. Agregar columna ultima_modificacion (según especificación Fase 13)
-- ============================================================================

USE lab_bdd;

-- ============================================================================
-- 1. ELIMINAR FOREIGN KEYS
-- ============================================================================
-- Las FK no tienen sentido en nodos shard porque la integridad referencial
-- se garantiza por diseño (co-localización de fragmentos derivados).
-- Además, MariaDB no permite particionar tablas con FK (Fase 12).

SELECT 'Eliminando FK constraints en shard...' AS '';

ALTER TABLE detalle_pedidos DROP FOREIGN KEY IF EXISTS detalle_pedidos_ibfk_1;
ALTER TABLE detalle_pedidos DROP FOREIGN KEY IF EXISTS detalle_pedidos_ibfk_2;
ALTER TABLE pedidos DROP FOREIGN KEY IF EXISTS pedidos_ibfk_1;

SELECT 'FK eliminadas. Verificando:' AS '';
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

-- ============================================================================
-- 2. CAMBIAR ENUM A VARCHAR
-- ============================================================================
-- Spider LIST COLUMNS (Fase 14) no soporta ENUM como partitioning key.
-- Todas las columnas usadas como clave de fragmentación deben ser VARCHAR.

SELECT 'Cambiando ENUM a VARCHAR en shard...' AS '';

ALTER TABLE clientes MODIFY COLUMN region VARCHAR(10) NOT NULL;
ALTER TABLE pedidos  MODIFY COLUMN region VARCHAR(10) NOT NULL;
ALTER TABLE pedidos  MODIFY COLUMN estado VARCHAR(20) NOT NULL DEFAULT 'pendiente';

SELECT 'Verificación de tipos:' AS '';
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND TABLE_NAME IN ('clientes', 'pedidos')
  AND COLUMN_NAME IN ('region', 'estado');

-- ============================================================================
-- 3. AGREGAR COLUMNA ultima_modificacion
-- ============================================================================
-- Según el DDD, los shards deben incluir metadatos de auditoría.

SELECT 'Agregando ultima_modificacion a tablas del shard...' AS '';

ALTER TABLE clientes      ADD COLUMN IF NOT EXISTS ultima_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER fecha_alta;
ALTER TABLE productos     ADD COLUMN IF NOT EXISTS ultima_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER fecha_creacion;
ALTER TABLE pedidos       ADD COLUMN IF NOT EXISTS ultima_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER total;
ALTER TABLE detalle_pedidos ADD COLUMN IF NOT EXISTS ultima_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER subtotal;

SELECT 'Columnas agregadas. Verificación:' AS '';
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, EXTRA
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND COLUMN_NAME = 'ultima_modificacion';

-- ============================================================================
-- 4. VERIFICACIÓN FINAL DEL ESQUEMA
-- ============================================================================
SELECT '=== Esquema del shard listo para Fase 13 ===' AS '';
SELECT COUNT(*) AS tablas_en_lab_bdd FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'lab_bdd';
