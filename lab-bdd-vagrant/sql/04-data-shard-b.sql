-- =============================================================
-- Datos para SHARD B (bdd-nodo05)
-- Solo regiones: sur, oeste
-- =============================================================
USE lab_bdd;

-- Clientes (sur = id 6-10, oeste = id 16-20)
INSERT INTO clientes (id, nombre, apellido, email, telefono, region, ciudad) VALUES
( 6, 'Miguel',   'Castro',     'miguel.castro@lab.test',    '9991000006', 'sur',    'Mérida'),
( 7, 'Sofía',    'Domínguez',  'sofia.dominguez@lab.test',  '9981000007', 'sur',    'Cancún'),
( 8, 'Jorge',    'Hernández',  'jorge.hernandez@lab.test',  '9511000008', 'sur',    'Oaxaca'),
( 9, 'Patricia', 'Vázquez',    'patricia.vazquez@lab.test', '9931000009', 'sur',    'Villahermosa'),
(10, 'Ernesto',  'Luna',       'ernesto.luna@lab.test',     '9611000010', 'sur',    'Tuxtla Gtz.'),
(16, 'Arturo',   'Flores',     'arturo.flores@lab.test',    '3331000016', 'oeste',  'Guadalajara'),
(17, 'Carmen',   'Rojas',      'carmen.rojas@lab.test',     '3121000017', 'oeste',  'Colima'),
(18, 'Ramón',    'Salinas',    'ramon.salinas@lab.test',    '3111000018', 'oeste',  'Tepic'),
(19, 'Lucía',    'Medina',     'lucia.medina@lab.test',     '4431000019', 'oeste',  'Morelia'),
(20, 'Eduardo',  'Vargas',     'eduardo.vargas@lab.test',   '4491000020', 'oeste',  'Aguascalientes');

-- Productos (todos, ambos shards tienen el catálogo completo)
INSERT INTO productos (id, sku, nombre, categoria, precio, stock,
                       descripcion, ficha_tecnica, peso_kg) VALUES
(1,  'ELEC-001', 'Monitor 24" FHD',      'Electrónica', 3500.00, 25,
 'Monitor LED 24 pulgadas Full HD 1920x1080, 75Hz, panel IPS.',
 'Resolución: 1920x1080 | Frecuencia: 75 Hz | Panel: IPS | Entradas: HDMI, VGA',
 3.200),
(2,  'ELEC-002', 'Teclado Mecánico TKL', 'Electrónica',  950.00, 40,
 'Teclado mecánico TKL con switches azules, retroiluminación RGB.',
 'Switches: Blue | Layout: TKL 87 teclas | Retroiluminación: RGB | Conector: USB-C',
 0.850),
(3,  'ELEC-003', 'Mouse Ergonómico',     'Electrónica',  480.00, 60,
 'Mouse inalámbrico ergonómico, sensor óptico 1600 DPI, receptor USB nano.',
 'DPI: 800/1200/1600 | Batería: AA 12 meses | Receptor: nano USB | Botones: 6',
 0.120),
(4,  'COMP-001', 'SSD 500 GB SATA',      'Almacenamiento', 1200.00, 30,
 'Unidad de estado sólido SATA III 500 GB, velocidad lectura 560 MB/s.',
 'Capacidad: 500 GB | Interfaz: SATA III | Lectura: 560 MB/s | Escritura: 520 MB/s',
 0.060),
(5,  'COMP-002', 'Memoria RAM 16 GB',    'Almacenamiento', 1850.00, 20,
 'Módulo de memoria DDR4 16 GB 3200 MHz, latencia CL16.',
 'Capacidad: 16 GB | Tipo: DDR4 | Velocidad: 3200 MHz | Latencia: CL16',
 0.040),
(6,  'RED-001',  'Switch 8 puertos',     'Redes',          650.00, 15,
 'Switch no administrado 8 puertos Gigabit Ethernet 10/100/1000.',
 'Puertos: 8 x GbE | Capacidad: 16 Gbps | Formato: Sobremesa | PoE: No',
 0.350),
(7,  'RED-002',  'Cable UTP Cat6 5m',    'Redes',           85.00, 120,
 'Cable de red UTP categoría 6 de 5 metros con conectores RJ45 moldeados.',
 'Categoría: Cat6 | Longitud: 5 m | Conector: RJ45 | Apantallamiento: UTP',
 0.100),
(8,  'PER-001',  'Silla Gamer Pro',      'Mobiliario',    4200.00,  8,
 'Silla de oficina/gaming con soporte lumbar, reposabrazos 4D y reclinación 135°.',
 'Material: Cuero PU | Reclinación: 90-135° | Reposabrazos: 4D | Peso máx: 120 kg',
 18.500),
(9,  'PER-002',  'Escritorio L 140 cm',  'Mobiliario',    2800.00,  5,
 'Escritorio en forma de L 140x120 cm con superficie de melamina 25 mm.',
 'Medidas: 140x120x75 cm | Material: MDP 25 mm | Acabado: Melamina | Color: Roble',
 35.000),
(10, 'ACC-001',  'Hub USB-C 7 en 1',     'Accesorios',     420.00, 50,
 'Hub multifunción USB-C con HDMI 4K, 3 USB-A 3.0, SD, MicroSD y USB-C PD 100W.',
 'Entradas: 1 USB-C | Salidas: HDMI 4K, 3xUSB-A, SD, MicroSD | PD: 100W',
 0.080);

-- Pedidos (sur = id 6-10, oeste = id 16-20)
INSERT INTO pedidos (id, cliente_id, region, estado, total) VALUES
( 6,  6, 'sur',   'entregado',  5050.00),
( 7,  7, 'sur',   'enviado',    2050.00),
( 8,  8, 'sur',   'procesado',   565.00),
( 9,  9, 'sur',   'pendiente',  4620.00),
(10, 10, 'sur',   'cancelado',   850.00),
(16, 16, 'oeste', 'entregado',  4650.00),
(17, 17, 'oeste', 'enviado',    3285.00),
(18, 18, 'oeste', 'procesado',   480.00),
(19, 19, 'oeste', 'pendiente',  7000.00),
(20, 20, 'oeste', 'entregado',  3220.00);

-- Detalle pedidos (solo pedidos de shard B)
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(6,  8, 1, 4200.00), (6,  2, 1,  950.00),
(7,  5, 1, 1850.00), (7,  3, 1,  480.00),
(8,  6, 1,  650.00), (8,  7, 1,   85.00),
(9,  4, 1, 1200.00), (9,  5, 1, 1850.00), (9,  8, 1, 4200.00),
(10, 2, 1,  950.00),
(16, 8, 1, 4200.00), (16, 3, 1,  480.00),
(17, 1, 1, 3500.00), (17, 7, 3,   85.00),
(18, 3, 1,  480.00),
(19, 9, 1, 2800.00), (19, 1, 1, 3500.00),
(20, 1, 1, 3500.00), (20, 7, 1,   85.00);

SELECT 'shard_b' AS nodo,
       (SELECT COUNT(*) FROM clientes) AS clientes,
       (SELECT COUNT(*) FROM productos) AS productos,
       (SELECT COUNT(*) FROM pedidos) AS pedidos,
       (SELECT COUNT(*) FROM detalle_pedidos) AS detalle;
