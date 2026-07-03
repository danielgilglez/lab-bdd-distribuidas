USE lab_bdd;
DELETE FROM clientes WHERE email = 'escritura.fragb@lab.test';
DELETE FROM v_productos_basico WHERE id = 11;
SELECT 'clientes post-limpieza' AS verificacion, COUNT(*) AS total FROM clientes
  UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
  UNION ALL SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
  UNION ALL SELECT 'v_productos_basico', COUNT(*) FROM v_productos_basico
  UNION ALL SELECT 'v_productos_detalle', COUNT(*) FROM v_productos_detalle
  UNION ALL SELECT 'productos', COUNT(*) FROM productos;
