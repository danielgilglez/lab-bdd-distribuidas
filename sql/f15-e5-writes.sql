USE lab_bdd;

-- INSERT region=norte → frag_A (nodo04)
INSERT INTO clientes (id, nombre, apellido, email, telefono, region, ciudad) VALUES (22, 'Escritura', 'FragA', 'escritura.fraga@lab.test', '5500000099', 'norte', 'Monterrey');
SELECT 'INSERT region=norte' AS paso, id, nombre, apellido, region, ciudad FROM clientes WHERE email = 'escritura.fraga@lab.test';

-- INSERT region=sur → frag_B (nodo05)
INSERT INTO clientes (id, nombre, apellido, email, telefono, region, ciudad) VALUES (23, 'Escritura', 'FragB', 'escritura.fragb@lab.test', '5500000098', 'sur', 'Guadalajara');
SELECT 'INSERT region=sur' AS paso, id, nombre, apellido, region, ciudad FROM clientes WHERE email = 'escritura.fragb@lab.test';

-- Conteo post-inserción
SELECT region, COUNT(*) AS clientes FROM clientes GROUP BY region ORDER BY region;

-- INSERT en v_productos_basico (Spider simple → nodo04)
INSERT INTO v_productos_basico (id, sku, nombre, categoria, precio, stock, fecha_creacion) VALUES (11, 'SKU-PRUEBA-011', 'Producto Prueba F15', 'Prueba', 99.99, 5, NOW());
SELECT 'INSERT v_productos_basico' AS paso, id, sku, nombre, precio FROM v_productos_basico WHERE id = 11;

-- UPDATE con predicado de region (dirigido a nodo04)
UPDATE clientes SET ciudad = 'San Pedro Garza García' WHERE email = 'escritura.fraga@lab.test' AND region = 'norte';
SELECT 'UPDATE dirigido (norte)' AS paso, id, nombre, ciudad, region FROM clientes WHERE email = 'escritura.fraga@lab.test';

-- UPDATE sin predicado (fan-out)
UPDATE clientes SET telefono = '5500000097' WHERE email = 'escritura.fragb@lab.test';
SELECT 'UPDATE fan-out' AS paso, id, nombre, telefono, region FROM clientes WHERE email = 'escritura.fragb@lab.test';

-- DELETE con predicado de region (dirigido a nodo04)
DELETE FROM clientes WHERE email = 'escritura.fraga@lab.test' AND region = 'norte';
SELECT 'DELETE dirigido' AS paso, COUNT(*) AS debe_ser_cero FROM clientes WHERE email = 'escritura.fraga@lab.test';
