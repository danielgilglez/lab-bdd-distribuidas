SELECT @@gtid_current_pos AS 'GTID_Actual';
SELECT 'clientes', COUNT(*) FROM lab_bdd.clientes
UNION ALL SELECT 'pedidos', COUNT(*) FROM lab_bdd.pedidos
UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM lab_bdd.detalle_pedidos
UNION ALL SELECT 'productos', COUNT(*) FROM lab_bdd.productos;
