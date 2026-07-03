-- ============================================================================
-- Fase 14 — Fragmento vertical B: v_productos_detalle (bdd-nodo05)
--
-- Crea:
--   1. Usuario spider_user para conexiones desde el coordinador (nodo06)
--   2. Tabla v_productos_detalle con columnas de detalle (TEXT)
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
-- 2. TABLA v_productos_detalle
-- ============================================================================
CREATE TABLE IF NOT EXISTS v_productos_detalle (
  id INT NOT NULL,
  sku VARCHAR(50) NOT NULL,
  descripcion TEXT,
  ficha_tecnica TEXT,
  imagen_url VARCHAR(500),
  peso_kg DECIMAL(8,3),
  PRIMARY KEY (id),
  KEY idx_sku (sku)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Fragmento vertical detalle de productos — Fase 14';

-- ============================================================================
-- 3. POBLAR DESDE LA TABLA productos
-- ============================================================================
INSERT INTO v_productos_detalle
  (id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg)
SELECT id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos;

-- ============================================================================
-- 4. VERIFICACIÓN
-- ============================================================================
SELECT 'v_productos_detalle poblado' AS resultado, COUNT(*) AS filas
FROM v_productos_detalle;
