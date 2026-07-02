-- Verificación del laboratorio de particionamiento
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

SELECT '=== lab_bdd.pedidos_part ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND TABLE_NAME = 'pedidos_part'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_bdd.pedidos_estado ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS estados,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_bdd'
  AND TABLE_NAME = 'pedidos_estado'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.pedidos ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS regiones,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== lab_particiones.pedidos_rangos ===' AS '';
SELECT PARTITION_NAME AS Particion,
       PARTITION_DESCRIPTION AS rango,
       TABLE_ROWS AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'lab_particiones'
  AND TABLE_NAME = 'pedidos_rangos'
ORDER BY PARTITION_ORDINAL_POSITION;

SELECT '=== Total filas por tabla ===' AS '';
SELECT 'clientes_list4' AS tabla, COUNT(*) AS total FROM lab_particiones.clientes_list4
UNION ALL
SELECT 'clientes_list2', COUNT(*) FROM lab_particiones.clientes_list2
UNION ALL
SELECT 'pedidos_part', COUNT(*) FROM lab_bdd.pedidos_part
UNION ALL
SELECT 'pedidos_estado', COUNT(*) FROM lab_bdd.pedidos_estado
UNION ALL
SELECT 'pedidos (lab_particiones)', COUNT(*) FROM lab_particiones.pedidos
UNION ALL
SELECT 'pedidos_rangos', COUNT(*) FROM lab_particiones.pedidos_rangos;
