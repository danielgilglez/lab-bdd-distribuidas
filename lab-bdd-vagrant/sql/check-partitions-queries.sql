-- Verificación de consultas y poda de particiones (Fase 12)
SELECT '=== clientes_list4 — con poda (region = norte) ===' AS '';
USE lab_particiones;
EXPLAIN SELECT id, nombre, email FROM clientes_list4 WHERE region = 'norte';

SELECT '=== clientes_list4 — sin poda ===' AS '';
EXPLAIN SELECT id, nombre, email FROM clientes_list4;

SELECT '=== clientes_list2 todas las filas ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2;

SELECT '=== clientes_list2 PARTITION (frag_A) ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2 PARTITION (frag_A);

SELECT '=== clientes_list2 PARTITION (frag_B) ===' AS '';
SELECT id, nombre, email, region FROM clientes_list2 PARTITION (frag_B);

SELECT '=== pedidos_list2 total por región ===' AS '';
SELECT COUNT(*) AS total, region FROM lab_particiones.pedidos_list2 GROUP BY region;
