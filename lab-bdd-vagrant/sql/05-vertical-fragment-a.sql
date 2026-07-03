-- ============================================================================
-- Fase 14 — Fragmento vertical A: v_productos_basico (bdd-nodo04)
--
-- Crea:
--   1. Usuario spider_user para conexiones desde el coordinador (nodo06)
--   2. Tabla v_productos_basico con columnas operacionales
--   3. Poblar desde la tabla productos (catálogo completo en ambos shards)
-- ============================================================================
USE lab_bdd;

-- ============================================================================
-- 1. USUARIO SPIDER PARA COORDINADOR
-- ============================================================================
CREATE USER IF NOT EXISTS 'spider_user'@'192.168.56.106'
  IDENTIFIED BY 'Spider_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.*
  TO 'spider_user'@'192.168.56.106';
FLUSH PRIVILEGES;

-- ============================================================================
-- 2. TABLA v_productos_basico
-- ============================================================================
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
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Fragmento vertical basico de productos — Fase 14';

-- ============================================================================
-- 3. POBLAR DESDE LA TABLA productos
-- ============================================================================
INSERT INTO v_productos_basico
  (id, sku, nombre, categoria, precio, stock, fecha_creacion)
SELECT id, sku, nombre, categoria, precio, stock, fecha_creacion
FROM productos;

-- ============================================================================
-- 4. VERIFICACIÓN
-- ============================================================================
SELECT 'v_productos_basico poblado' AS resultado, COUNT(*) AS filas
FROM v_productos_basico;
