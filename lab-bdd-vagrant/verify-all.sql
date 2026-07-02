SELECT '========================================' AS '';
SELECT 'VERIFICACION COMPLETA DE LABORATORIO' AS '';
SELECT '========================================' AS '';

SELECT '--- 1. VERSION MARIADB ---' AS '';
SELECT VERSION() AS version;

SELECT '--- 2. BASES DE DATOS ---' AS '';
SHOW DATABASES;

SELECT '--- 3. TABLAS EN lab_bdd ---' AS '';
SELECT TABLE_NAME, ENGINE, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='lab_bdd' AND TABLE_TYPE='BASE TABLE'
ORDER BY TABLE_NAME;

SELECT '--- 4. USUARIOS ---' AS '';
SELECT User, Host, plugin FROM mysql.user WHERE Host != 'localhost' OR User IN ('root','app_user','lab_admin','repl_user');

SELECT '--- 5. TOTAL CLIENTES ---' AS '';
SELECT COUNT(*) AS total, COUNT(DISTINCT region) AS regiones FROM clientes;

SELECT '--- 6. CLIENTES POR REGION ---' AS '';
SELECT region, COUNT(*) AS cnt FROM clientes GROUP BY region ORDER BY region;

SELECT '--- 7. TOTAL PEDIDOS ---' AS '';
SELECT COUNT(*) AS total FROM pedidos;

SELECT '--- 8. PEDIDOS POR REGION ---' AS '';
SELECT region, COUNT(*) AS cnt FROM pedidos GROUP BY region ORDER BY region;

SELECT '--- 9. TOTAL DETALLE ---' AS '';
SELECT COUNT(*) AS total FROM detalle_pedidos;

SELECT '--- 10. TOTAL PRODUCTOS ---' AS '';
SELECT COUNT(*) AS total FROM productos;

SELECT '--- 11. PRODUCTOS POR REGION (via clientes) ---' AS '';
SELECT c.region, COUNT(DISTINCT dp.producto_id) AS productos_usados
FROM detalle_pedidos dp
JOIN pedidos p ON dp.pedido_id = p.id
JOIN clientes c ON p.cliente_id = c.id
GROUP BY c.region ORDER BY c.region;

SELECT '--- 12. PLUGINS ACTIVOS ---' AS '';
SHOW PLUGINS;

SELECT '--- 13. VARIABLES DE REPLICACION ---' AS '';
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'gtid_domain_id';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'read_only';
