-- ============================================================================
-- Verificación de Fragmentación Horizontal (Fase 13)
-- Ejecutar en bdd-nodo01 (maestro) para validar shards remotos
-- ============================================================================

-- ============================================================================
-- 1. COMPLETITUD: suma de filas en shards = total original
-- ============================================================================
SELECT '=== COMPLETITUD: suma de shards vs total original ===' AS '';

SELECT 'clientes' AS tabla,
       (SELECT COUNT(*) FROM lab_bdd.clientes) AS total_original;

-- Estos conteos deben ejecutarse via conexión remota desde el coordinador
-- (nodo06) o localmente en cada shard. Aquí se documenta lo esperado:
-- Shard A (nodo04): 10 clientes (norte=5, este=5)
-- Shard B (nodo05): 10 clientes (sur=5, oeste=5)
-- Total: 20 = 10 + 10

-- ============================================================================
-- 2. DISJUNCIÓN: regiones no deben solaparse entre shards
-- ============================================================================
SELECT '=== DISJUNCIÓN: regiones únicas por shard ===' AS '';

-- En shard A solo debe haber norte y este
SELECT region, COUNT(*) AS clientes
FROM lab_bdd.clientes
WHERE region IN ('norte', 'este')
GROUP BY region WITH ROLLUP;

-- En shard B solo debe haber sur y oeste
SELECT region, COUNT(*) AS clientes
FROM lab_bdd.clientes
WHERE region IN ('sur', 'oeste')
GROUP BY region WITH ROLLUP;

-- ============================================================================
-- 3. CO-LOCALIZACIÓN: pedidos y sus detalles en el mismo shard
-- ============================================================================
SELECT '=== CO-LOCALIZACIÓN: pedidos con sus clientes en mismo shard ===' AS '';

SELECT COUNT(*) AS pedidos_con_cliente_en_shard
FROM lab_bdd.pedidos p
JOIN lab_bdd.clientes c ON p.cliente_id = c.id
WHERE p.region = c.region;

-- ============================================================================
-- 4. RECONSTRUCCIÓN: UNION ALL desde shards
-- ============================================================================
SELECT '=== RECONSTRUCCIÓN: UNION ALL desde bdd-nodo01 ===' AS '';

-- Simulación: desde el maestro se puede verificar que
-- SELECT * FROM nodo04.clientes UNION ALL SELECT * FROM nodo05.clientes
-- = 20 clientes

-- ============================================================================
-- 5. DISTRIBUCIÓN POR REGIÓN
-- ============================================================================
SELECT '=== DISTRIBUCIÓN POR REGIÓN ===' AS '';

SELECT region, COUNT(*) AS clientes
FROM lab_bdd.clientes
GROUP BY region
ORDER BY region;

SELECT region, COUNT(*) AS pedidos
FROM lab_bdd.pedidos
GROUP BY region
ORDER BY region;
