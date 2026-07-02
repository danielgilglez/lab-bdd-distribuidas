-- =============================================================
-- Datos para SHARD A (bdd-nodo04)
-- Solo regiones: norte, este
-- =============================================================
USE lab_bdd;

-- Clientes (norte = id 1-5, este = id 11-15)
INSERT INTO clientes (id, nombre, apellido, email, telefono, region, ciudad) VALUES
( 1, 'Ana',      'Gutiérrez',  'ana.gutierrez@lab.test',    '8181000001', 'norte',  'Monterrey'),
( 2, 'Carlos',   'Mendoza',    'carlos.mendoza@lab.test',   '6141000002', 'norte',  'Chihuahua'),
( 3, 'Laura',    'Ibarra',     'laura.ibarra@lab.test',     '6641000003', 'norte',  'Tijuana'),
( 4, 'Roberto',  'Soto',       'roberto.soto@lab.test',     '6621000004', 'norte',  'Hermosillo'),
( 5, 'Verónica', 'Reyes',      'veronica.reyes@lab.test',   '8711000005', 'norte',  'Torreón'),
(11, 'Isabel',   'Morales',    'isabel.morales@lab.test',   '2291000011', 'este',   'Veracruz'),
(12, 'Héctor',   'Jiménez',    'hector.jimenez@lab.test',   '2281000012', 'este',   'Xalapa'),
(13, 'Daniela',  'Torres',     'daniela.torres@lab.test',   '8331000013', 'este',   'Tampico'),
(14, 'Alejandro','Ríos',       'alejandro.rios@lab.test',   '9211000014', 'este',   'Coatzacoalcos'),
(15, 'Fernanda', 'Peña',       'fernanda.pena@lab.test',    '7821000015', 'este',   'Poza Rica');

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

-- Pedidos (norte = id 1-5, este = id 11-15)
INSERT INTO pedidos (id, cliente_id, region, estado, total) VALUES
( 1,  1, 'norte', 'entregado',  4450.00),
( 2,  2, 'norte', 'enviado',    1430.00),
( 3,  3, 'norte', 'procesado',  3500.00),
( 4,  4, 'norte', 'pendiente',  2800.00),
( 5,  5, 'norte', 'entregado',   735.00),
(11, 11, 'este',  'entregado',  1200.00),
(12, 12, 'este',  'enviado',    3980.00),
(13, 13, 'este',  'procesado',  6020.00),
(14, 14, 'este',  'pendiente',   505.00),
(15, 15, 'este',  'entregado',  1650.00);

-- Detalle pedidos (solo pedidos de shard A)
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1,  1, 1, 3500.00), (1,  3, 2,  480.00),
(2,  2, 1,  950.00), (2,  3, 1,  480.00),
(3,  1, 1, 3500.00),
(4,  9, 1, 2800.00),
(5,  7, 5,   85.00), (5,  6, 1,  650.00),
(11, 4, 1, 1200.00),
(12, 1, 1, 3500.00), (12, 10, 1,  420.00),
(13, 8, 1, 4200.00), (13, 9, 1, 2800.00),
(14, 7, 3,   85.00), (14, 6, 1,  650.00),
(15, 5, 1, 1850.00);

SELECT 'shard_a' AS nodo,
       (SELECT COUNT(*) FROM clientes) AS clientes,
       (SELECT COUNT(*) FROM productos) AS productos,
       (SELECT COUNT(*) FROM pedidos) AS pedidos,
       (SELECT COUNT(*) FROM detalle_pedidos) AS detalle;
