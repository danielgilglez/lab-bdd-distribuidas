USE lab_bdd;
DROP PROCEDURE IF EXISTS analizar_consulta;
DELIMITER //
CREATE PROCEDURE analizar_consulta(
  IN p_region VARCHAR(10),
  IN p_incluir_vertical BOOLEAN
)
COMMENT 'Muestra el plan de descomposicion estimado y el grado de localidad'
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
USE lab_bdd;
SELECT '--- analizar_consulta(norte, FALSE) ---' AS demo;
CALL analizar_consulta('norte', FALSE);
SELECT '--- analizar_consulta(NULL, TRUE) ---' AS demo;
CALL analizar_consulta(NULL, TRUE);
