-- ============================================================================
-- check-spider.sql — Verificación de Fase 14 (Coordinador Spider)
--
-- Ejecutar en bdd-nodo06 como root:
--   sudo mariadb < /vagrant/sql/check-spider.sql
-- ============================================================================

SELECT '=== FASE 14 — VERIFICACIÓN DEL COORDINADOR SPIDER ===' AS '';

-- ============================================================================
-- 1. ESTADO DEL PLUGIN SPIDER
-- ============================================================================
SELECT '1. Plugin Spider' AS prueba;
SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_VERSION
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'SPIDER';

-- ============================================================================
-- 2. TABLAS DE SISTEMA SPIDER
-- ============================================================================
SELECT '2. Tablas de sistema Spider' AS prueba;
SHOW TABLES IN mysql LIKE 'spider%';

-- ============================================================================
-- 3. CONFIGURACIÓN DEL COORDINADOR
-- ============================================================================
SELECT '3. Variables del coordinador' AS prueba;
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'read_only';
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'skip_name_resolve';

-- ============================================================================
-- 4. SERVIDORES REMOTOS REGISTRADOS
-- ============================================================================
SELECT '4. Servidores remotos (CREATE SERVER)' AS prueba;
SELECT Server_name, Host, Db, Username
FROM mysql.servers
ORDER BY Server_name;

-- ============================================================================
-- 5. TABLAS EN lab_bdd
-- ============================================================================
SELECT '5. Tablas en lab_bdd' AS prueba;
SHOW TABLES IN lab_bdd;

-- ============================================================================
-- 6. VERIFICACIÓN DE DATOS — FRAGMENTOS HORIZONTALES
-- ============================================================================
SELECT '6. Conteo de fragmentos horizontales' AS prueba;
SELECT 'clientes (Spider, 2 shards)' AS fuente, COUNT(*) AS filas
FROM lab_bdd.clientes
UNION ALL
SELECT 'pedidos (Spider, 2 shards)', COUNT(*)
FROM lab_bdd.pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*)
FROM lab_bdd.detalle_pedidos;

-- ============================================================================
-- 7. VERIFICACIÓN DE DATOS — FRAGMENTOS VERTICALES
-- ============================================================================
SELECT '7. Conteo de fragmentos verticales' AS prueba;
SELECT 'v_productos_basico (Spider → nodo04)' AS fuente, COUNT(*) AS filas
FROM lab_bdd.v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider → nodo05)', COUNT(*)
FROM lab_bdd.v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN distribuido)', COUNT(*)
FROM lab_bdd.productos;

-- ============================================================================
-- 8. PODA DE PARTICIONES (EXPLAIN)
-- ============================================================================
SELECT '8. Poda de particiones (EXPLAIN)' AS prueba;
EXPLAIN SELECT id, nombre, ciudad
FROM lab_bdd.clientes
WHERE region = 'norte';

EXPLAIN SELECT id, nombre, ciudad
FROM lab_bdd.clientes;

-- ============================================================================
-- 9. CONSULTA DISTRIBUIDA — FICHA DE PRODUCTO
-- ============================================================================
SELECT '9. Producto completo (JOIN distribuido)' AS prueba;
SELECT id, sku, nombre, categoria, precio, stock,
       LEFT(descripcion, 50) AS descripcion_preview,
       peso_kg
FROM lab_bdd.productos
WHERE id = 1;

-- ============================================================================
-- 10. CONSULTA HÍBRIDA — FACTURACIÓN POR REGIÓN
-- ============================================================================
SELECT '10. Facturación por región (híbrida)' AS prueba;
SELECT c.region,
       COUNT(DISTINCT c.id) AS clientes_activos,
       COUNT(DISTINCT p.id) AS num_pedidos,
       ROUND(SUM(dp.subtotal), 2) AS facturacion_total
FROM lab_bdd.clientes c
JOIN lab_bdd.pedidos p ON p.cliente_id = c.id
JOIN lab_bdd.detalle_pedidos dp ON dp.pedido_id = p.id
JOIN lab_bdd.v_productos_basico vb ON vb.id = dp.producto_id
GROUP BY c.region
ORDER BY facturacion_total DESC;

SELECT '=== VERIFICACIÓN COMPLETADA ===' AS '';
