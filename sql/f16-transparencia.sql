USE lab_bdd;

-- E.12: app_final para bdd-cliente
CREATE USER IF NOT EXISTS 'app_final'@'192.168.56.107' IDENTIFIED BY 'AppFinal_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* TO 'app_final'@'192.168.56.107';
GRANT EXECUTE ON lab_bdd.* TO 'app_final'@'192.168.56.107';
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User = 'app_final' ORDER BY Host;

-- E.13: Pruebas de transparencia (simuladas desde nodo06 como app_final)
SELECT '=== PRUEBA 1: Conexion al sistema distribuido ===' AS prueba;
SELECT @@hostname AS servidor, @@server_id AS server_id, DATABASE() AS db;

SELECT '=== PRUEBA 2: Objetos del esquema ===' AS prueba;
SHOW TABLES;

SELECT '=== PRUEBA 3: Lectura global (2 shards) ===' AS prueba;
SELECT region, COUNT(*) AS total_clientes FROM clientes GROUP BY region ORDER BY region;

SELECT '=== PRUEBA 4: Poda automatica (solo un shard) ===' AS prueba;
SELECT id, nombre, apellido, ciudad FROM clientes WHERE region = 'norte' ORDER BY id;

SELECT '=== PRUEBA 5: JOIN distribuido vertical ===' AS prueba;
SELECT id, sku, nombre, categoria, precio, LEFT(descripcion, 60) AS descripcion_preview, peso_kg FROM productos ORDER BY categoria, precio;

SELECT '=== PRUEBA 6: Reporte via vista encapsulada ===' AS prueba;
SELECT region, COUNT(*) AS lineas, ROUND(SUM(subtotal), 2) AS total FROM reporte_pedidos_detallado GROUP BY region ORDER BY total DESC;

SELECT '=== PRUEBA 7: Procedimiento almacenado ===' AS prueba;
CALL consulta_regional(NULL);

SELECT '=== Resumen global ===' AS prueba;
SELECT 'clientes' AS tabla, COUNT(*) FROM clientes
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
UNION ALL SELECT 'v_productos_basico', COUNT(*) FROM v_productos_basico
UNION ALL SELECT 'v_productos_detalle', COUNT(*) FROM v_productos_detalle
UNION ALL SELECT 'productos(VIEW)', COUNT(*) FROM productos;
