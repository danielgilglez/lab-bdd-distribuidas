-- Verificación de consultas específicas del laboratorio
SELECT '=== clientes_list4 en esclavo ===' AS '';
USE lab_particiones;
SELECT id, nombre, email FROM clientes_list4;

SELECT '=== clientes_list2 todas las filas ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2;

SELECT '=== clientes_list2 PARTITION (frag_A) ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2 PARTITION (frag_A);

SELECT '=== clientes_list2 PARTITION (frag_B) ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2 PARTITION (frag_B);

SELECT '=== pedidos en lab_particiones ===' AS '';
SELECT COUNT(*) AS total, region FROM lab_particiones.pedidos GROUP BY region;
