-- ---- Estado global del servidor ----
-- Conexiones acumuladas desde el último arranque
SHOW GLOBAL STATUS LIKE 'Connections';
-- Conexiones activas en este momento
SHOW GLOBAL STATUS LIKE 'Threads_connected';
-- Consultas ejecutadas desde el arranque
SHOW GLOBAL STATUS LIKE 'Questions';
-- Bytes enviados y recibidos
SHOW GLOBAL STATUS LIKE 'Bytes_%';
-- Operaciones de InnoDB (lecturas/escrituras de páginas)
SHOW GLOBAL STATUS LIKE 'Innodb_pages_%';
-- ---- Procesos activos ----
-- Lista todos los hilos de conexión activos en este momento
SHOW FULL PROCESSLIST;
-- ---- Estado de InnoDB ----
-- Salida extensa; incluye buffer pool, transacciones activas,
-- locks, I/O. Se usa para diagnóstico avanzado.
SHOW ENGINE INNODB STATUS\G
-- ---- Resumen de tablas del laboratorio ----
SELECT TABLE_NAME            AS tabla,
       TABLE_ROWS            AS filas_aprox,
       ROUND(DATA_LENGTH/1024, 1)  AS datos_KB,
       ROUND(INDEX_LENGTH/1024, 1) AS indices_KB
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'lab_bdd'
ORDER BY DATA_LENGTH DESC;
-- ---- Consulta de negocio de ejemplo para verificar los datos ----
SELECT c.region,
       COUNT(DISTINCT c.id)   AS clientes,
       COUNT(p.id)            AS pedidos,
       ROUND(SUM(p.total), 2) AS ingresos_total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.region
ORDER BY ingresos_total DESC;
