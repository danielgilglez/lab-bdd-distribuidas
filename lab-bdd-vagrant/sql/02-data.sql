USE lab_bdd;
-- -------------------- CLIENTES (20 registros, 5 por region) --------------------
INSERT INTO clientes (nombre, apellido, email, telefono, region, ciudad) VALUES
-- Norte
('Ana',      'Gutiérrez',  'ana.gutierrez@lab.test',    '8181000001', 'norte',  'Monterrey'),
('Carlos',   'Mendoza',    'carlos.mendoza@lab.test',   '6141000002', 'norte',  'Chihuahua'),
('Laura',    'Ibarra',     'laura.ibarra@lab.test',     '6641000003', 'norte',  'Tijuana'),
('Roberto',  'Soto',       'roberto.soto@lab.test',     '6621000004', 'norte',  'Hermosillo'),
('Verónica', 'Reyes',      'veronica.reyes@lab.test',   '8711000005', 'norte',  'Torreón'),
-- Sur
('Miguel',   'Castro',     'miguel.castro@lab.test',    '9991000006', 'sur',    'Mérida'),
('Sofía',    'Domínguez',  'sofia.dominguez@lab.test',  '9981000007', 'sur',    'Cancún'),
('Jorge',    'Hernández',  'jorge.hernandez@lab.test',  '9511000008', 'sur',    'Oaxaca'),
('Patricia', 'Vázquez',    'patricia.vazquez@lab.test', '9931000009', 'sur',    'Villahermosa'),
('Ernesto',  'Luna',       'ernesto.luna@lab.test',     '9611000010', 'sur',    'Tuxtla Gtz.'),
-- Este
('Isabel',   'Morales',    'isabel.morales@lab.test',   '2291000011', 'este',   'Veracruz'),
('Héctor',   'Jiménez',    'hector.jimenez@lab.test',   '2281000012', 'este',   'Xalapa'),
('Daniela',  'Torres',     'daniela.torres@lab.test',   '8331000013', 'este',   'Tampico'),
('Alejandro','Ríos',       'alejandro.rios@lab.test',   '9211000014', 'este',   'Coatzacoalcos'),
('Fernanda', 'Peña',       'fernanda.pena@lab.test',    '7821000015', 'este',   'Poza Rica'),
-- Oeste
('Arturo',   'Flores',     'arturo.flores@lab.test',    '3331000016', 'oeste',  'Guadalajara'),
('Carmen',   'Rojas',      'carmen.rojas@lab.test',     '3121000017', 'oeste',  'Colima'),
('Ramón',    'Salinas',    'ramon.salinas@lab.test',    '3111000018', 'oeste',  'Tepic'),
('Lucía',    'Medina',     'lucia.medina@lab.test',     '4431000019', 'oeste',  'Morelia'),
('Eduardo',  'Vargas',     'eduardo.vargas@lab.test',   '4491000020', 'oeste',  'Aguascalientes');
-- -------------------- PRODUCTOS (10 registros) --------------------
INSERT INTO productos (sku, nombre, categoria, precio, stock,
                       descripcion, ficha_tecnica, peso_kg) VALUES
('ELEC-001', 'Monitor 24" FHD',      'Electrónica', 3500.00, 25,
 'Monitor LED 24 pulgadas Full HD 1920x1080, 75Hz, panel IPS.',
 'Resolución: 1920x1080 | Frecuencia: 75 Hz | Panel: IPS | Entradas: HDMI, VGA',
 3.200),
('ELEC-002', 'Teclado Mecánico TKL', 'Electrónica',  950.00, 40,
 'Teclado mecánico TKL con switches azules, retroiluminación RGB.',
 'Switches: Blue | Layout: TKL 87 teclas | Retroiluminación: RGB | Conector: USB-C',
 0.850),
('ELEC-003', 'Mouse Ergonómico',     'Electrónica',  480.00, 60,
 'Mouse inalámbrico ergonómico, sensor óptico 1600 DPI, receptor USB nano.',
 'DPI: 800/1200/1600 | Batería: AA 12 meses | Receptor: nano USB | Botones: 6',
 0.120),
('COMP-001', 'SSD 500 GB SATA',      'Almacenamiento', 1200.00, 30,
 'Unidad de estado sólido SATA III 500 GB, velocidad lectura 560 MB/s.',
 'Capacidad: 500 GB | Interfaz: SATA III | Lectura: 560 MB/s | Escritura: 520 MB/s',
 0.060),
('COMP-002', 'Memoria RAM 16 GB',    'Almacenamiento', 1850.00, 20,
 'Módulo de memoria DDR4 16 GB 3200 MHz, latencia CL16.',
 'Capacidad: 16 GB | Tipo: DDR4 | Velocidad: 3200 MHz | Latencia: CL16',
 0.040),
('RED-001',  'Switch 8 puertos',     'Redes',          650.00, 15,
 'Switch no administrado 8 puertos Gigabit Ethernet 10/100/1000.',
 'Puertos: 8 x GbE | Capacidad: 16 Gbps | Formato: Sobremesa | PoE: No',
 0.350),
('RED-002',  'Cable UTP Cat6 5m',    'Redes',           85.00, 120,
 'Cable de red UTP categoría 6 de 5 metros con conectores RJ45 moldeados.',
 'Categoría: Cat6 | Longitud: 5 m | Conector: RJ45 | Apantallamiento: UTP',
 0.100),
('PER-001',  'Silla Gamer Pro',      'Mobiliario',    4200.00,  8,
 'Silla de oficina/gaming con soporte lumbar, reposabrazos 4D y reclinación 135°.',
 'Material: Cuero PU | Reclinación: 90-135° | Reposabrazos: 4D | Peso máx: 120 kg',
 18.500),
('PER-002',  'Escritorio L 140 cm',  'Mobiliario',    2800.00,  5,
 'Escritorio en forma de L 140x120 cm con superficie de melamina 25 mm.',
 'Medidas: 140x120x75 cm | Material: MDP 25 mm | Acabado: Melamina | Color: Roble',
 35.000),
('ACC-001',  'Hub USB-C 7 en 1',     'Accesorios',     420.00, 50,
 'Hub multifunción USB-C con HDMI 4K, 3 USB-A 3.0, SD, MicroSD y USB-C PD 100W.',
 'Entradas: 1 USB-C | Salidas: HDMI 4K, 3xUSB-A, SD, MicroSD | PD: 100W',
 0.080);
-- -------------------- PEDIDOS (20 registros, mix de regiones y estados) --------------------
INSERT INTO pedidos (cliente_id, region, estado, total) VALUES
( 1, 'norte', 'entregado',  4450.00),
( 2, 'norte', 'enviado',    1430.00),
( 3, 'norte', 'procesado',  3500.00),
( 4, 'norte', 'pendiente',  2800.00),
( 5, 'norte', 'entregado',   735.00),
( 6, 'sur',   'entregado',  5050.00),
( 7, 'sur',   'enviado',    2050.00),
( 8, 'sur',   'procesado',   565.00),
( 9, 'sur',   'pendiente',  4620.00),
(10, 'sur',   'cancelado',   850.00),
(11, 'este',  'entregado',  1200.00),
(12, 'este',  'enviado',    3980.00),
(13, 'este',  'procesado',  6020.00),
(14, 'este',  'pendiente',   505.00),
(15, 'este',  'entregado',  1650.00),
(16, 'oeste', 'entregado',  4650.00),
(17, 'oeste', 'enviado',    3285.00),
(18, 'oeste', 'procesado',   480.00),
(19, 'oeste', 'pendiente',  7000.00),
(20, 'oeste', 'entregado',  3220.00);
-- -------------------- DETALLE_PEDIDOS --------------------
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1,  1, 1, 3500.00), (1,  3, 2,  480.00),
(2,  2, 1,  950.00), (2,  3, 1,  480.00),
(3,  1, 1, 3500.00),
(4,  9, 1, 2800.00),
(5,  7, 5,   85.00), (5,  6, 1,  650.00),
(6,  8, 1, 4200.00), (6,  2, 1,  950.00),
(7,  5, 1, 1850.00), (7,  3, 1,  480.00),
(8,  6, 1,  650.00), (8,  7, 1,   85.00),
(9,  4, 1, 1200.00), (9,  5, 1, 1850.00), (9,  8, 1, 4200.00),
(10, 2, 1,  950.00),
(11, 4, 1, 1200.00),
(12, 1, 1, 3500.00), (12, 10, 1,  420.00),
(13, 8, 1, 4200.00), (13, 9, 1, 2800.00),
(14, 7, 3,   85.00), (14, 6, 1,  650.00),
(15, 5, 1, 1850.00),
(16, 8, 1, 4200.00), (16, 3, 1,  480.00),
(17, 1, 1, 3500.00), (17, 7, 3,   85.00),
(18, 3, 1,  480.00),
(19, 9, 1, 2800.00), (19, 1, 1, 3500.00),
(20, 1, 1, 3500.00), (20, 7, 1,   85.00);
-- Actualizar totales calculados en pedidos
UPDATE pedidos p
SET total = (
    SELECT SUM(subtotal)
    FROM detalle_pedidos dp
    WHERE dp.pedido_id = p.id
);
-- Resumen final
SELECT 'clientes'        AS tabla, COUNT(*) AS registros FROM clientes    UNION ALL
SELECT 'productos',                COUNT(*)               FROM productos   UNION ALL
SELECT 'pedidos',                  COUNT(*)               FROM pedidos     UNION ALL
SELECT 'detalle_pedidos',          COUNT(*)               FROM detalle_pedidos;
