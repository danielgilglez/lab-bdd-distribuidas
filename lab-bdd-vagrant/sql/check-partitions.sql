-- Verificación del laboratorio de particionamiento (Fase 12)
SELECT '=== lab_particiones.clientes_list4 ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS region_cubierta,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list4'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.clientes_list2 ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_list2'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.pedidos_list2 ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_list2'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.pedidos_range ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS rango,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_range'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.accesos_hash ===' AS '';
SELECT PARTITION_NAME AS Particion,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'accesos_hash'
ORDER BY PARTITION_NAME;

SELECT '=== lab_particiones.log_eventos_key ===' AS '';
SELECT PARTITION_NAME AS Particion,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'log_eventos_key'
ORDER BY PARTITION_NAME;

SELECT '=== lab_particiones.clientes_subpart ===' AS '';
SELECT PARTITION_NAME AS Particion,
       SUBPARTITION_NAME AS Subparticion,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'clientes_subpart'
ORDER BY PARTITION_ORDINAL_POSITION, SUBPARTITION_ORDINAL_POSITION;

SELECT '=== Total filas por tabla ===' AS '';
SELECT 'clientes_list4' AS tabla, COUNT(*) AS total FROM lab_particiones.clientes_list4
UNION ALL
SELECT 'clientes_list2', COUNT(*) FROM lab_particiones.clientes_list2
UNION ALL
SELECT 'pedidos_list2', COUNT(*) FROM lab_particiones.pedidos_list2
UNION ALL
SELECT 'pedidos_range', COUNT(*) FROM lab_particiones.pedidos_range
UNION ALL
SELECT 'accesos_hash', COUNT(*) FROM lab_particiones.accesos_hash
UNION ALL
SELECT 'log_eventos_key', COUNT(*) FROM lab_particiones.log_eventos_key
UNION ALL
SELECT 'clientes_subpart', COUNT(*) FROM lab_particiones.clientes_subpart;
