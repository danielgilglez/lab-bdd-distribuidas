USE lab_bdd;

-- ==============================================================
-- FASE 16 — E.3 a E.8
-- ==============================================================

-- ==============================================================
-- E.3: Análisis estadístico de costes
-- ==============================================================
SELECT '=== E.3: Costes de transferencia estimados ===' AS paso;

SELECT fragmento, tabla_origen, nodo, ip, filas_aprox, bytes_por_fila,
  filas_aprox * bytes_por_fila AS bytes_transfer_max,
  ROUND(filas_aprox * bytes_por_fila / 1024.0, 1) AS KB_transfer_max
FROM (
  SELECT 'clientes_frag_A' AS fragmento, 'clientes' AS tabla_origen, 'bdd-nodo04' AS nodo, '192.168.56.104' AS ip, 10 AS filas_aprox, 120 AS bytes_por_fila
  UNION ALL SELECT 'pedidos_frag_A', 'pedidos', 'bdd-nodo04', '192.168.56.104', 10, 90
  UNION ALL SELECT 'detalle_frag_A', 'detalle_pedidos', 'bdd-nodo04', '192.168.56.104', 18, 60
  UNION ALL SELECT 'v_productos_basico', 'v_productos_basico', 'bdd-nodo04', '192.168.56.104', 10, 100
  UNION ALL SELECT 'clientes_frag_B', 'clientes', 'bdd-nodo05', '192.168.56.105', 10, 120
  UNION ALL SELECT 'pedidos_frag_B', 'pedidos', 'bdd-nodo05', '192.168.56.105', 10, 90
  UNION ALL SELECT 'detalle_frag_B', 'detalle_pedidos', 'bdd-nodo05', '192.168.56.105', 18, 60
  UNION ALL SELECT 'v_productos_detalle', 'v_productos_detalle', 'bdd-nodo05', '192.168.56.105', 10, 150
) AS costes ORDER BY nodo, bytes_transfer_max DESC;

SELECT 'Coste maximo total' AS escenario,
  ROUND((10*120+10*90+18*60+10*100+10*120+10*90+18*60+10*150)/1024.0, 1) AS total_KB;
SELECT 'Coste H-1 (grado 0, solo nodo04)' AS escenario,
  ROUND((10*120+10*90+18*60+10*100)/1024.0, 1) AS total_KB;

-- ==============================================================
-- E.4: Simulación manual de 4 fases de descomposición
-- ==============================================================
SELECT '=== E.4: FASE 1 — Descomposición (proyección temprana) ===' AS fase;
SELECT c.region, c.id AS c_id, p.id AS p_id, dp.subtotal, dp.producto_id, vb.categoria
FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id
ORDER BY c.region LIMIT 6;

SELECT '=== E.4: FASE 2 — Localización (fragmentos) ===' AS fase;
SELECT 'clientes localizado' AS rel_local, region, COUNT(*) AS filas
FROM (SELECT region FROM clientes WHERE region IN ('norte','este')
      UNION ALL SELECT region FROM clientes WHERE region IN ('sur','oeste')) AS clientes_localizados
GROUP BY region ORDER BY region;

SELECT 'Simplificación: region=norte elimina frag_B' AS demo;
SELECT 'frag_A (norte+este)' AS fragmento, COUNT(*) AS filas_relevantes
FROM clientes WHERE region IN ('norte','este')
UNION ALL
SELECT 'frag_B (sur+oeste) — ELIMINADO', COUNT(*)
FROM clientes WHERE region IN ('sur','oeste') AND region = 'norte';

SELECT '=== E.4: FASE 3 — Optimización global (sub-agregación) ===' AS fase;
SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos,
  GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria) AS categorias,
  ROUND(SUM(dp.subtotal), 2) AS facturacion
FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
JOIN spider_detalle_nodo04 dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id
WHERE c.region IN ('norte', 'este')
GROUP BY c.region;

SELECT '=== E.4: FASE 4 — Ejecución distribuida (ensamblado) ===' AS fase;
SELECT region, SUM(clientes_activos) AS clientes_activos, SUM(pedidos) AS pedidos,
  GROUP_CONCAT(DISTINCT categorias ORDER BY categorias SEPARATOR ', ') AS categorias,
  ROUND(SUM(facturacion), 2) AS facturacion_total
FROM (
  SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos,
    GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria) AS categorias,
    ROUND(SUM(dp.subtotal), 2) AS facturacion
  FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
  JOIN spider_detalle_nodo04 dp ON dp.pedido_id = p.id
  JOIN v_productos_basico vb ON vb.id = dp.producto_id
  WHERE c.region IN ('norte', 'este')
  GROUP BY c.region
  UNION ALL
  SELECT c.region, COUNT(DISTINCT c.id), COUNT(DISTINCT p.id),
    GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria),
    ROUND(SUM(dp.subtotal), 2)
  FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
  JOIN spider_detalle_nodo05 dp ON dp.pedido_id = p.id
  JOIN v_productos_basico vb ON vb.id = dp.producto_id
  WHERE c.region IN ('sur', 'oeste')
  GROUP BY c.region
) AS resultados_parciales
GROUP BY region ORDER BY facturacion_total DESC;

SELECT '=== Referencia: H-6 directa (mismo resultado) ===' AS fase;
SELECT c.region, COUNT(DISTINCT c.id) AS clientes_activos, COUNT(DISTINCT p.id) AS pedidos,
  GROUP_CONCAT(DISTINCT vb.categoria ORDER BY vb.categoria SEPARATOR ', ') AS categorias,
  ROUND(SUM(dp.subtotal), 2) AS facturacion_total
FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id
GROUP BY c.region ORDER BY facturacion_total DESC;

-- ==============================================================
-- E.5: Semijoin distribuida manual (Bernstein-Chiu)
-- ==============================================================
SELECT '=== E.5: Semijoin — Bernstein-Chiu ===' AS paso;

SELECT '--- A: JOIN naive ---' AS estrategia;
FLUSH STATUS;
SELECT dp.pedido_id, vb.nombre AS producto, vb.categoria, dp.cantidad, dp.subtotal
FROM detalle_pedidos dp JOIN v_productos_basico vb ON vb.id = dp.producto_id
ORDER BY dp.pedido_id LIMIT 10;
SHOW STATUS WHERE Variable_name IN ('Handler_read_rnd_next','Handler_read_key','Handler_read_next','Bytes_sent');

SELECT '--- B.1: IDs unicos de join ---' AS paso;
SELECT DISTINCT producto_id AS id_join FROM detalle_pedidos ORDER BY producto_id;

SELECT '--- B.2: v_productos_basico reducido ---' AS paso;
SELECT id, nombre, categoria, precio
FROM v_productos_basico
WHERE id IN (SELECT DISTINCT producto_id FROM detalle_pedidos);

SELECT '--- B.3: JOIN con semijoin ---' AS paso;
FLUSH STATUS;
SELECT dp.pedido_id, vb.nombre AS producto, vb.categoria, dp.cantidad, dp.subtotal
FROM detalle_pedidos dp JOIN v_productos_basico vb ON vb.id = dp.producto_id
  AND vb.id IN (SELECT DISTINCT producto_id FROM detalle_pedidos)
ORDER BY dp.pedido_id LIMIT 10;
SHOW STATUS WHERE Variable_name IN ('Handler_read_rnd_next','Handler_read_key','Handler_read_next','Bytes_sent');

SELECT '--- Analisis beneficio ---' AS paso;
SELECT 'B.1: solo IDs' AS etapa, COUNT(DISTINCT producto_id) AS filas, COUNT(DISTINCT producto_id) * 4 AS bytes FROM detalle_pedidos
UNION ALL
SELECT 'A: v_productos_basico completo', COUNT(*), COUNT(*) * 100 FROM v_productos_basico
UNION ALL
SELECT 'B.2: v_productos_basico reducido', COUNT(*), COUNT(*) * 100
FROM v_productos_basico WHERE id IN (SELECT DISTINCT producto_id FROM detalle_pedidos);

-- ==============================================================
-- E.6: Proyección temprana vs SELECT *
-- ==============================================================
SELECT '=== E.6: Proyección temprana vs SELECT * ===' AS paso;

SELECT '--- V1: SELECT * ---' AS experimento;
FLUSH STATUS;
SELECT * FROM clientes WHERE region = 'norte';
SHOW STATUS WHERE Variable_name IN ('Handler_read_rnd_next','Handler_read_key','Handler_read_next','Bytes_sent');

SELECT '--- V2: Proyección explícita (4 columnas) ---' AS experimento;
FLUSH STATUS;
SELECT id, nombre, apellido, region FROM clientes WHERE region = 'norte';
SHOW STATUS WHERE Variable_name IN ('Handler_read_rnd_next','Handler_read_key','Handler_read_next','Bytes_sent');

-- ==============================================================
-- E.7: EXPLAIN desde nodo06 (poda por partición)
-- ==============================================================
SELECT '=== E.7: EXPLAIN poda por partición ===' AS paso;
SELECT 'A1: clientes SIN filtro' AS v; EXPLAIN SELECT id, nombre, region FROM clientes;
SELECT 'A2: clientes region=norte' AS v; EXPLAIN SELECT id, nombre, region FROM clientes WHERE region = 'norte';
SELECT 'A3: clientes IN (norte,este)' AS v; EXPLAIN SELECT id, nombre, region FROM clientes WHERE region IN ('norte','este');
SELECT 'A4: clientes IN (norte,sur)' AS v; EXPLAIN SELECT id, nombre, region FROM clientes WHERE region IN ('norte','sur');
SELECT 'B1: pedidos IN (sur,oeste)' AS v; EXPLAIN SELECT id, total FROM pedidos WHERE region IN ('sur','oeste');
SELECT 'C1: detalle_pedidos VIEW' AS v; EXPLAIN SELECT COUNT(*) FROM detalle_pedidos;
SELECT 'C2: spider_detalle_nodo04' AS v; EXPLAIN SELECT COUNT(*) FROM spider_detalle_nodo04;
SELECT 'D1: v_productos_basico id=1' AS v; EXPLAIN SELECT id, nombre FROM v_productos_basico WHERE id = 1;
SELECT 'D2: productos VIEW' AS v; EXPLAIN SELECT id, nombre, descripcion FROM productos WHERE id = 1;

-- ==============================================================
-- E.8: Crear procedimiento analizar_consulta()
-- ==============================================================
DROP PROCEDURE IF EXISTS analizar_consulta;
DELIMITER //
CREATE PROCEDURE analizar_consulta(
  IN p_region VARCHAR(10),
  IN p_incluir_vertical BOOLEAN
)
COMMENT 'Muestra el plan de descomposición estimado y el grado de localidad'
BEGIN
  DECLARE v_nodo_h VARCHAR(30) DEFAULT 'nodo04+nodo05 (ambos)';
  DECLARE v_filas_h INT DEFAULT 20;
  DECLARE v_filas_dp INT DEFAULT 34;
  DECLARE v_grado TINYINT DEFAULT 1;
  IF p_region IN ('norte', 'este') THEN
    SET v_nodo_h = 'bdd-nodo04 (frag_A)';
    SET v_filas_h = 10;
    SET v_filas_dp = 15;
    SET v_grado = IF(p_incluir_vertical, 1, 0);
  ELSEIF p_region IN ('sur', 'oeste') THEN
    SET v_nodo_h = 'bdd-nodo05 (frag_B)';
    SET v_filas_h = 10;
    SET v_filas_dp = 19;
    SET v_grado = IF(p_incluir_vertical, 1, 0);
  ELSE
    SET v_grado = IF(p_incluir_vertical, 2, 1);
  END IF;
  SELECT CONCAT('PLAN | Region: ', COALESCE(p_region, 'TODAS'),
    ' | Vertical: ', IF(p_incluir_vertical, 'SI', 'NO'),
    ' | Grado: ', v_grado) AS descripcion_plan;
  SELECT fragmento, nodo_fisico, filas_est, bytes_por_fila,
    filas_est * bytes_por_fila AS bytes_transfer_est,
    ROUND(filas_est * bytes_por_fila / 1024.0, 2) AS KB_est
  FROM (
    SELECT 'clientes' AS fragmento, v_nodo_h AS nodo_fisico, v_filas_h AS filas_est, 120 AS bytes_por_fila, 1 AS ord
    UNION ALL SELECT 'pedidos', v_nodo_h, v_filas_h, 90, 2
    UNION ALL SELECT 'detalle_pedidos', v_nodo_h, v_filas_dp, 60, 3
    UNION ALL SELECT 'v_productos_basico', 'bdd-nodo04 (siempre)', 10, 100, 4
    UNION ALL SELECT 'v_productos_detalle', 'bdd-nodo05 (siempre)', IF(p_incluir_vertical, 10, 0), IF(p_incluir_vertical, 150, 0), 5
  ) AS plan WHERE filas_est > 0 ORDER BY ord;
  SELECT ROUND((v_filas_h*120+v_filas_h*90+v_filas_dp*60+10*100+IF(p_incluir_vertical,10*150,0))/1024.0, 1) AS total_KB_estimado,
    v_grado AS grado_localidad;
END //
DELIMITER ;

SELECT '--- analizar_consulta(norte, FALSE) ---' AS demo;
CALL analizar_consulta('norte', FALSE);
SELECT '--- analizar_consulta(NULL, TRUE) ---' AS demo;
CALL analizar_consulta(NULL, TRUE);
