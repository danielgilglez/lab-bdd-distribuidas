SELECT '=== ENGINES ===' AS '';
SHOW ENGINES;

SELECT '=== TABLES ===' AS '';
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='lab_bdd' AND TABLE_TYPE='BASE TABLE';

SELECT '=== CLIENTES TOTAL ===' AS '';
SELECT COUNT(*) AS total_clientes FROM clientes;

SELECT '=== CLIENTES POR REGION ===' AS '';
SELECT region, COUNT(*) AS cnt FROM clientes GROUP BY region;

SELECT '=== PEDIDOS TOTAL ===' AS '';
SELECT COUNT(*) AS total_pedidos FROM pedidos;

SELECT '=== DETALLE TOTAL ===' AS '';
SELECT COUNT(*) AS total_detalle FROM detalle_pedidos;

SELECT '=== PRODUCTOS BASICO ===' AS '';
SELECT COUNT(*) AS total FROM productos_basico;

SELECT '=== PRODUCTOS DETALLE ===' AS '';
SELECT COUNT(*) AS total FROM productos_detalle;
