USE lab_bdd;

-- ==============================================================
-- E.3 CATÁLOGO DE CONSULTAS HÍBRIDAS H-1 a H-8
-- ==============================================================
SELECT '=== H-1: Grado 0 — Solo nodo04 (máxima localidad) ===' AS consulta;
SELECT c.region, CONCAT(c.nombre, ' ', c.apellido) AS cliente, c.ciudad, p.id AS pedido_id, p.estado, vb.sku, vb.nombre AS producto, vb.categoria, vb.precio, dp.cantidad, dp.subtotal FROM clientes c JOIN pedidos p ON p.cliente_id = c.id JOIN spider_detalle_nodo04 dp ON dp.pedido_id = p.id JOIN v_productos_basico vb ON vb.id = dp.producto_id WHERE c.region IN ('norte', 'este') ORDER BY c.region, p.id;

SELECT '=== H-2: Grado 1a — Horizontal puro (nodo04+nodo05) ===' AS consulta;
SELECT c.region, COUNT(DISTINCT c.id) AS clientes, COUNT(DISTINCT p.id) AS pedidos, ROUND(SUM(p.total), 2) AS facturacion_total, MIN(p.fecha_pedido) AS primer_pedido, MAX(p.fecha_pedido) AS ultimo_pedido FROM clientes c JOIN pedidos p ON p.cliente_id = c.id GROUP BY c.region ORDER BY facturacion_total DESC;

SELECT '=== H-3: Grado 1b — Vertical puro, JOIN distribuido nodo04+nodo05 ===' AS consulta;
SELECT pr.id, pr.sku, pr.nombre, pr.categoria, pr.precio, pr.stock, LEFT(pr.descripcion, 70) AS descripcion_preview, LEFT(pr.ficha_tecnica, 70) AS ficha_preview, pr.peso_kg FROM productos pr ORDER BY pr.categoria, pr.nombre;

SELECT '=== H-4: Grado 2 parcial — Un shard horizontal + ambos verticales ===' AS consulta;
SELECT c.region, CONCAT(c.nombre, ' ', c.apellido) AS cliente, p.id AS pedido_id, pr.nombre AS producto, pr.categoria, pr.precio, LEFT(pr.descripcion, 60) AS descripcion_preview, pr.peso_kg, dp.cantidad, dp.subtotal FROM clientes c JOIN pedidos p ON p.cliente_id = c.id JOIN detalle_pedidos dp ON dp.pedido_id = p.id JOIN productos pr ON pr.id = dp.producto_id WHERE c.region IN ('norte', 'este') ORDER BY p.id;

SELECT '=== H-5: Grado 2 parcial — Ambos horizontales + solo basico nodo04 ===' AS consulta;
SELECT c.region, vb.categoria, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos, SUM(dp.cantidad) AS unidades_vendidas, ROUND(SUM(dp.subtotal), 2) AS facturacion FROM clientes c JOIN pedidos p ON p.cliente_id = c.id JOIN detalle_pedidos dp ON dp.pedido_id = p.id JOIN v_productos_basico vb ON vb.id = dp.producto_id GROUP BY c.region, vb.categoria ORDER BY c.region, facturacion DESC;

SELECT '=== H-6: Grado 2 total — Consulta DDD Fase 9 (distribución completa) ===' AS consulta;
SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos, GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria SEPARATOR ', ') AS categorias_compradas, ROUND(SUM(dp.subtotal), 2) AS facturacion_total FROM clientes c JOIN pedidos p ON p.cliente_id = c.id JOIN detalle_pedidos dp ON dp.pedido_id = p.id JOIN v_productos_basico vb ON vb.id = dp.producto_id GROUP BY c.region ORDER BY facturacion_total DESC;

SELECT '=== H-7: Grado 2 total — Reporte analítico avanzado ===' AS consulta;
SELECT vb.nombre AS producto, vb.categoria, vb.precio AS precio_catalogo, vd.peso_kg, LEFT(vd.descripcion, 80) AS descripcion_corta, COUNT(DISTINCT p.region) AS regiones_de_venta, GROUP_CONCAT(DISTINCT p.region ORDER BY p.region SEPARATOR ', ') AS lista_regiones, SUM(dp.cantidad) AS total_unidades, ROUND(SUM(dp.subtotal), 2) AS total_facturado, ROUND(AVG(dp.precio_unitario), 2) AS precio_promedio_venta FROM v_productos_basico vb JOIN v_productos_detalle vd ON vd.id = vb.id JOIN detalle_pedidos dp ON dp.producto_id = vb.id JOIN pedidos p ON p.id = dp.pedido_id GROUP BY vb.id, vb.nombre, vb.categoria, vb.precio, vd.peso_kg, vd.descripcion ORDER BY total_facturado DESC;

SELECT '=== H-8: Grado 0 optimizado — Equivalente regional de H-6 (solo nodo04) ===' AS consulta;
SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos, GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria SEPARATOR ', ') AS categorias_compradas, ROUND(SUM(dp.subtotal), 2) AS facturacion_total FROM clientes c JOIN pedidos p ON p.cliente_id = c.id JOIN spider_detalle_nodo04 dp ON dp.pedido_id = p.id JOIN v_productos_basico vb ON vb.id = dp.producto_id WHERE c.region IN ('norte', 'este') GROUP BY c.region ORDER BY facturacion_total DESC;

-- ==============================================================
-- E.4 EXPLAIN: estrategias de optimización
-- ==============================================================
SELECT '-- A1: clientes SIN filtro ---' AS experimento;
EXPLAIN SELECT id, nombre, region FROM clientes;
SELECT '-- A2: clientes CON region=norte ---' AS experimento;
EXPLAIN SELECT id, nombre, region FROM clientes WHERE region = 'norte';
SELECT '-- A3: clientes region IN (norte,este) ---' AS experimento;
EXPLAIN SELECT id, nombre, region FROM clientes WHERE region IN ('norte', 'este');
SELECT '-- A4: clientes region IN (norte,sur) ---' AS experimento;
EXPLAIN SELECT id, nombre, region FROM clientes WHERE region IN ('norte', 'sur');
SELECT '-- B1: pedidos con region=sur+oeste ---' AS experimento;
EXPLAIN SELECT id, total FROM pedidos WHERE region IN ('sur', 'oeste');
SELECT '-- B2: pedidos sin filtro ---' AS experimento;
EXPLAIN SELECT COUNT(*), SUM(total) FROM pedidos;
SELECT '-- C1: detalle_pedidos VIEW ---' AS experimento;
EXPLAIN SELECT COUNT(*) FROM detalle_pedidos;
SELECT '-- C2: spider_detalle_nodo04 directa ---' AS experimento;
EXPLAIN SELECT COUNT(*) FROM spider_detalle_nodo04;
SELECT '-- C3: spider_detalle_nodo05 directa ---' AS experimento;
EXPLAIN SELECT COUNT(*) FROM spider_detalle_nodo05;
SELECT '-- D1: SELECT * FROM productos ---' AS experimento;
EXPLAIN SELECT id, nombre, descripcion FROM productos WHERE id = 1;
SELECT '-- D2: SELECT FROM v_productos_basico ---' AS experimento;
EXPLAIN SELECT id, nombre, precio FROM v_productos_basico WHERE id = 1;
SELECT '-- E1: JOIN clientes+pedidos con region=norte ---' AS experimento;
EXPLAIN SELECT c.nombre, p.total FROM clientes c JOIN pedidos p ON p.cliente_id = c.id WHERE c.region = 'norte';

-- ==============================================================
-- E.6: Objetos de negocio
-- ==============================================================
CREATE OR REPLACE VIEW reporte_pedidos_detallado AS
SELECT c.region, CONCAT(c.nombre, ' ', c.apellido) AS cliente, c.ciudad, c.email, p.id AS pedido_id, p.fecha_pedido, p.estado, p.total AS total_pedido, vb.sku, vb.nombre AS producto, vb.categoria, vb.precio AS precio_catalogo, dp.cantidad, dp.precio_unitario, dp.subtotal
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id;

SELECT 'Vista reporte_pedidos_detallado — 5 filas' AS verificacion;
SELECT region, cliente, ciudad, pedido_id, estado, producto, categoria, subtotal FROM reporte_pedidos_detallado ORDER BY region, pedido_id LIMIT 5;

SELECT region, COUNT(*) AS lineas, ROUND(SUM(subtotal),2) AS total FROM reporte_pedidos_detallado GROUP BY region ORDER BY region;

DROP PROCEDURE IF EXISTS consulta_regional;
DELIMITER //
CREATE PROCEDURE consulta_regional(IN p_region VARCHAR(10))
COMMENT 'Resumen de ventas por region. Pasar NULL para todas las regiones.'
BEGIN
  IF p_region IS NOT NULL THEN
    SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos_totales, GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria SEPARATOR ', ') AS categorias, ROUND(SUM(dp.subtotal), 2) AS facturacion, ROUND(SUM(dp.subtotal) / COUNT(DISTINCT p.id), 2) AS ticket_promedio
    FROM clientes c
    JOIN pedidos p ON p.cliente_id = c.id
    JOIN detalle_pedidos dp ON dp.pedido_id = p.id
    JOIN v_productos_basico vb ON vb.id = dp.producto_id
    WHERE c.region = p_region
    GROUP BY c.region;
  ELSE
    SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos_totales, GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria SEPARATOR ', ') AS categorias, ROUND(SUM(dp.subtotal), 2) AS facturacion, ROUND(SUM(dp.subtotal) / COUNT(DISTINCT p.id), 2) AS ticket_promedio
    FROM clientes c
    JOIN pedidos p ON p.cliente_id = c.id
    JOIN detalle_pedidos dp ON dp.pedido_id = p.id
    JOIN v_productos_basico vb ON vb.id = dp.producto_id
    GROUP BY c.region
    ORDER BY facturacion DESC;
  END IF;
END //
DELIMITER ;

SELECT '--- CALL consulta_regional(NULL) ---' AS demo;
CALL consulta_regional(NULL);
SELECT '--- CALL consulta_regional(norte) ---' AS demo;
CALL consulta_regional('norte');

-- ==============================================================
-- E.7: Usuario app_final y transparencia
-- ==============================================================
CREATE USER IF NOT EXISTS 'app_final'@'192.168.56.1' IDENTIFIED BY 'AppFinal_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* TO 'app_final'@'192.168.56.1';
GRANT EXECUTE ON lab_bdd.* TO 'app_final'@'192.168.56.1';
FLUSH PRIVILEGES;
SELECT 'Usuario app_final creado' AS resultado;

-- Confirmar objetos del coordinador
SELECT TABLE_NAME AS objeto, TABLE_TYPE AS tipo, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'lab_bdd' ORDER BY TABLE_TYPE DESC, TABLE_NAME;
SELECT ROUTINE_NAME AS procedimiento, ROUTINE_TYPE, ROUTINE_COMMENT FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'lab_bdd';
