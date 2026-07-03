USE lab_bdd;
ALTER TABLE pedidos ADD INDEX IF NOT EXISTS idx_region_cliente (region, cliente_id);
ALTER TABLE clientes ADD INDEX IF NOT EXISTS idx_region_id (region, id);
ALTER TABLE v_productos_basico ADD INDEX IF NOT EXISTS idx_categoria (categoria);
ALTER TABLE v_productos_basico ADD INDEX IF NOT EXISTS idx_precio (precio);
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columnas, CASE WHEN NON_UNIQUE = 0 THEN 'UNIQUE' ELSE 'normal' END AS tipo FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = 'lab_bdd' GROUP BY TABLE_NAME, INDEX_NAME ORDER BY TABLE_NAME, INDEX_NAME;
