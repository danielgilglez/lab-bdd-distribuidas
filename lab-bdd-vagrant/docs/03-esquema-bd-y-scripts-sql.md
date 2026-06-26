# Esquema de Base de Datos y Scripts SQL

## Base de datos: `lab_bdd`

### Tabla: `clientes`
Fragmentación horizontal por `region` (Fase 13).

| Columna | Tipo | Restricción |
|---------|------|-------------|
| id | INT | AUTO_INCREMENT, PRIMARY KEY |
| nombre | VARCHAR(100) | NOT NULL |
| apellido | VARCHAR(100) | NOT NULL |
| email | VARCHAR(150) | UNIQUE |
| telefono | VARCHAR(20) | |
| region | ENUM('norte','sur','este','oeste') | NOT NULL |
| ciudad | VARCHAR(100) | |
| fecha_alta | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Tabla: `productos`
Fragmentación vertical: básico vs detalle (Fase 14).

| Columna | Tipo | Restricción |
|---------|------|-------------|
| id | INT | AUTO_INCREMENT, PRIMARY KEY |
| sku | VARCHAR(50) | NOT NULL, UNIQUE |
| nombre | VARCHAR(150) | NOT NULL |
| categoria | VARCHAR(50) | |
| precio | DECIMAL(10,2) | NOT NULL |
| stock | INT | DEFAULT 0 |
| descripcion | TEXT | (candidata a nodo separado) |
| ficha_tecnica | TEXT | (candidata a nodo separado) |
| imagen_url | VARCHAR(255) | |
| peso_kg | DECIMAL(6,3) | |
| fecha_creacion | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Tabla: `pedidos`
Fragmentación horizontal por `region` (Fase 13).

| Columna | Tipo | Restricción |
|---------|------|-------------|
| id | INT | AUTO_INCREMENT, PRIMARY KEY |
| cliente_id | INT | NOT NULL, FK → clientes(id) |
| region | ENUM('norte','sur','este','oeste') | NOT NULL |
| fecha_pedido | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| estado | ENUM('pendiente','procesado','enviado','entregado','cancelado') | DEFAULT 'pendiente' |
| total | DECIMAL(10,2) | |

### Tabla: `detalle_pedidos`
Relación N:M entre pedidos y productos.

| Columna | Tipo | Restricción |
|---------|------|-------------|
| id | INT | AUTO_INCREMENT, PRIMARY KEY |
| pedido_id | INT | NOT NULL, FK → pedidos(id) |
| producto_id | INT | NOT NULL, FK → productos(id) |
| cantidad | INT | NOT NULL, CHECK(cantidad > 0) |
| precio_unitario | DECIMAL(10,2) | NOT NULL |
| subtotal | DECIMAL(10,2) | GENERATED ALWAYS AS (cantidad * precio_unitario) STORED |

## Scripts SQL disponibles

| Archivo | Descripción |
|---------|-------------|
| `sql/01-schema.sql` | Creación del esquema completo |
| `sql/02-data.sql` | Datos de prueba (20 clientes, 10 productos, 20 pedidos, 35 detalle) |
| `sql/03-users.sql` | Creación de usuarios (app_user, lab_admin, repl_user) |
| `sql/04-spider-setup.sql` | Configuración de Spider (solo para nodo06) |

## Archivos auxiliares en /vagrant/

| Archivo | Descripción |
|---------|-------------|
| `master_dump.sql` | Dump completo del maestro con GTID |
| `insert.sql` | Script de prueba de inserción |
