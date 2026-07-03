# Guía de Referencia Rápida — Laboratorio de Bases de Datos Distribuidas (MariaDB)

Este documento sirve como la **Única Fuente de Verdad (Single Source of Truth - SSoT)** del laboratorio. Consolida, resume y estructura las 17 fases académicas (Fase 0 a Fase 16) en un formato de lectura rápida y alta densidad de información, diseñado para ser consumido eficientemente tanto por humanos como por agentes de Inteligencia Artificial.

---

## 🗺️ Mapa General de la Arquitectura Distribuida

### Topología de Red y Nodos

* **Red Host-Only de VirtualBox**: `192.168.56.0/24` (IP del Host: `192.168.56.1`, DHCP desactivado).
* **Usuario del Sistema Operativo**: `bddadmin` (Contraseña: `bddadmin`, con privilegios sudo).

| Nodo | IP Estática | Rol en MariaDB | server_id | Características Clave | Fases |
|---|---|---|---|---|---|---|
| **bdd-nodo01** | `192.168.56.101` | **Master** | `1` | Binlog ROW, GTID activo, lectura/escritura | Fase 10 |
| **bdd-nodo02** | `192.168.56.102` | **Slave** | `2` | Replica física de nodo01, `read_only = ON` | Fase 10 |
| **bdd-nodo03** | `192.168.56.103` | **Multimaster** | `3` | Par síncrono (Galera) o réplica lógica bidireccional | Fase 11 |
| **bdd-nodo04** | `192.168.56.104` | **Shard A** | `4` | Fragmento Horizontal (Norte/Este) + Vert. Básico | Fases 13-16 |
| **bdd-nodo05** | `192.168.56.105` | **Shard B** | `5` | Fragmento Horizontal (Sur/Oeste) + Vert. Detalle | Fases 13-16 |
| **bdd-nodo06** | `192.168.56.106** | **Spider Coordinator** | `6` | Motor Spider activo, no almacena datos locales | Fases 14-16 |
| **bdd-nodo07** | `192.168.56.107` | **Cliente** | — | Estación cliente ligera sin MariaDB, solo `mariadb-client` | Fase 16 |

### Credenciales de MariaDB

| Usuario | Contraseña | Ámbito | Privilegios |
|---|---|---|---|
| **root** | `LabAdmin_2025!` | `localhost`, `%` | Superusuario administrativo completo |
| **lab_admin** | `LabAdmin_2025!` | `localhost`, `%` | `ALL PRIVILEGES ON lab_bdd.*` |
| **app_user** | `AppUser_2025!` | `localhost`, `%` | `SELECT, INSERT, UPDATE, DELETE ON lab_bdd.*` |
| **repl_user** | `ReplUser_2025!` | `%` o IP específica | `REPLICATION SLAVE ON *.*` |

---

## 📊 Modelo de Datos Global (`lab_bdd`)

El laboratorio utiliza un esquema relacional básico de comercio electrónico con **4 tablas**:

1. **`clientes`** (20 registros): Contiene `id`, `nombre`, `apellido`, `email`, `telefono`, `region` (`norte`, `sur`, `este`, `oeste`), `ciudad`, `fecha_alta`.
2. **`productos`** (10 registros): Contiene `id`, `sku`, `nombre`, `categoria`, `precio`, `stock`, `descripcion`, `ficha_tecnica`, `imagen_url`, `peso_kg`, `fecha_creacion`.
3. **`pedidos`** (20 registros): Contiene `id`, `cliente_id` (FK), `region`, `fecha_pedido`, `estado`, `total`.
4. **`detalle_pedidos`** (33 registros en script real / 36 teóricos): Contiene `id`, `pedido_id` (FK), `producto_id` (FK), `cantidad`, `precio_unitario`, `subtotal` (columna generada/calculada).

---

## ⏱️ Resumen Ejecutivo de las Fases (0 a 16)

### Fase 0 — Planeación y Diseño del Laboratorio
* **Objetivo**: Diseñar la topología de red, direccionamiento IP, dimensionamiento de hardware y plan de crecimiento (de 2 a 6 nodos).
* **Conceptos clave**: Redes virtuales, aislamiento de bases de datos, direccionamiento estático.
* **Resultados**: Matriz de direccionamiento IP (`192.168.56.101` a `.106`) y plan de snapshots para control de versiones del laboratorio.

### Fase 1 — Instalación de Oracle VirtualBox
* **Objetivo**: Instalar y preparar el hipervisor VirtualBox en el host.
* **Conceptos clave**: Virtualización tipo 2, extensiones de VirtualBox (Extension Pack).
* **Resultados**: VirtualBox 7.x instalado con soporte para virtualización por hardware activo.

### Fase 2 — Configuración de la Red Virtual Host-Only
* **Objetivo**: Crear un canal de comunicación aislado pero accesible desde el host para las VMs.
* **Comandos clave**:
  ```bash
  VBoxManage hostonlyif create
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
  VBoxManage dhcpserver modify --ifname vboxnet0 --disable
  ```
* **Verificación**: El adaptador `vboxnet0` (o equivalente) tiene la IP `192.168.56.1` y el DHCP está desactivado.

### Fase 3 — Creación de las Primeras Máquinas Virtuales
* **Objetivo**: Configurar el hardware virtual para `bdd-nodo01` y `bdd-nodo02`.
* **Especificaciones de Hardware**:
  * **vCPUs**: 2 | **RAM**: 1.5 GB (1536 MB) | **Disco**: 20 GB dinámico.
  * **Adaptador 1**: Host-Only (vboxnet0) | **Adaptador 2**: NAT (para acceso a internet temporal).
* **Verificación**: VMs creadas con orden de arranque `dvd,disk` y controladoras de almacenamiento SATA/IDE listas.

### Fase 4 — Descarga y Verificación de la Imagen ISO de Ubuntu Server
* **Objetivo**: Obtener y validar el instalador del sistema operativo.
* **Comandos clave**:
  ```powershell
  Get-FileHash .\ubuntu-24.04-live-server-amd64.iso -Algorithm SHA256
  ```
* **Resultados**: ISO descargada y hash verificado contra el oficial de Canonical.

### Fase 5 — Instalación de Ubuntu Server 24.04 LTS
* **Objetivo**: Instalar el sistema operativo base en `bdd-nodo01` y `bdd-nodo02`.
* **Configuraciones clave**:
  * Instalador: Subiquity.
  * Usuario: `bddadmin` / `bddadmin`.
  * Paquete obligatorio: Marcar la casilla **Install OpenSSH Server**.
* **Verificación**: Acceso local exitoso a la consola TUI de Ubuntu en ambos nodos. Snapshot: `fase05-completa`.

### Fase 6 — Configuración de IP Estática (Netplan)
* **Objetivo**: Fijar las direcciones IP de los nodos y configurar la resolución local de nombres.
* **Configuración Clave (`/etc/netplan/50-cloud-init.yaml`)**:
  ```yaml
  network:
    version: 2
    ethernets:
      enp0s3:
        addresses:
          - 192.168.56.101/24 # .102 para nodo02
        routes: [] # Sin gateway en Host-Only
  ```
* **Resolución de nombres (`/etc/hosts`)**:
  ```text
  192.168.56.101 bdd-nodo01
  192.168.56.102 bdd-nodo02
  ```
* **Verificación**: `ping 192.168.56.101` y `ssh bddadmin@bdd-nodo01` conectan exitosamente desde el host. Snapshot: `fase06-completa`.

### Fase 7 — Instalación y Configuración Inicial de MariaDB Server
* **Objetivo**: Instalar el motor de base de datos y asegurar su acceso.
* **Comandos clave**:
  ```bash
  sudo apt update && sudo apt install -y mariadb-server mariadb-client
  sudo mariadb-secure-installation # Establecer root password: LabAdmin_2025!
  ```
* **Configuración de Charset (`/etc/mysql/mariadb.conf.d/99-lab-charset.cnf`)**:
  ```ini
  [server]
  character-set-server = utf8mb4
  collation-server = utf8mb4_unicode_ci
  [client]
  default-character-set = utf8mb4
  ```
* **Acceso Externo**: Cambiar `bind-address = 127.0.0.1` a `bind-address = 0.0.0.0` en `/etc/mysql/mariadb.conf.d/50-server.cnf`.
* **Verificación**: `SELECT VERSION();` devuelve `10.11.x-MariaDB`. Conexión TCP externa permitida. Snapshot: `fase07-completa`.

### Fase 8 — Administración Básica de MariaDB
* **Objetivo**: Implementar el esquema relacional, cargar datos, configurar seguridad y logs.
* **Esquema y Datos**: Ejecución de `01-schema.sql` y `02-data.sql`.
* **Configuración de Usuarios**:
  ```sql
  CREATE USER 'lab_admin'@'localhost' IDENTIFIED BY 'LabAdmin_2025!';
  GRANT ALL PRIVILEGES ON lab_bdd.* TO 'lab_admin'@'localhost';
  
  CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'AppUser_2025!';
  GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.* TO 'app_user'@'localhost';
  ```
* **Configuración de Logs (`/etc/mysql/mariadb.conf.d/99-lab-logs.cnf`)**:
  ```ini
  [mariadb]
  slow_query_log = ON
  slow_query_log_file = /var/log/mysql/mariadb-slow.log
  long_query_time = 2
  ```
* **Verificación**: `app_user` puede hacer `SELECT` pero recibe `Access denied` al intentar un `DROP TABLE`. Snapshot: `fase08-completa`.

### Fase 9 — Diseño de la Arquitectura Distribuida
* **Objetivo**: Elaborar el Documento de Diseño Distribuido (DDD) con los planes de replicación, fragmentación horizontal y fragmentación vertical.
* **Planes de Distribución**:
  * **Replicación**: Física (nodo01 -> nodo02), Lógica/Galera (nodo01 <-> nodo03).
  * **Fragmentación Horizontal**: Tabla `clientes` y `pedidos` divididas por `region` (Shard A: Norte/Este en nodo04, Shard B: Sur/Oeste en nodo05).
  * **Fragmentación Vertical**: Tabla `productos` dividida en columnas básicas (nodo04) y columnas de detalle (nodo05).
* **Verificación**: Correctitud del diseño validada mediante las reglas de completitud, reconstrucción y disjunción. Snapshot: `fase09-completa`.

### Fase 10 — Replicación Física (Maestro-Esclavo)
* **Objetivo**: Configurar replicación asíncrona unidireccional basada en GTID.
* **Configuración del Maestro (`bdd-nodo01` - `60-replication.cnf`)**:
  ```ini
  [mariadb]
  server_id = 1
  log_bin = /var/log/mysql/mariadb-bin
  binlog_format = ROW
  gtid_domain_id = 1
  ```
* **Configuración del Esclavo (`bdd-nodo02` - `60-replication.cnf`)**:
  ```ini
  [mariadb]
  server_id = 2
  read_only = ON
  ```
* **Comandos de Activación**:
  * *En Maestro*: `CREATE USER 'repl_user'@'%' IDENTIFIED BY 'ReplUser_2025!'; GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';`
  * *En Esclavo*:
    ```sql
    CHANGE MASTER TO
      MASTER_HOST = '192.168.56.101',
      MASTER_USER = 'repl_user',
      MASTER_PASSWORD = 'ReplUser_2025!',
      MASTER_USE_GTID = slave_pos;
    START SLAVE;
    ```
* **Verificación**: `SHOW SLAVE STATUS\G` muestra `Slave_IO_Running: Yes` y `Slave_SQL_Running: Yes`. Un insert en el maestro aparece instantáneamente en el esclavo. Snapshot: `fase10-completa`.

### Fase 11 — Replicación Lógica Multi-Maestro (Galera Cluster)
* **Objetivo**: Implementar replicación síncrona multi-maestro añadiendo `bdd-nodo03` (`192.168.56.103`).
* **Conceptos clave**: Certificación de transacciones, Write-sets, Componente Primario, Quórum, SST (rsync) e IST.
* **Configuración Galera (`/etc/mysql/mariadb.conf.d/61-galera.cnf`)**:
  ```ini
  [mariadb]
  wsrep_on = ON
  wsrep_provider = /usr/lib/galera/libgalera_smm.so
  wsrep_cluster_address = "gcomm://192.168.56.101,192.168.56.102,192.168.56.103"
  wsrep_node_address = "192.168.56.101" # IP de cada nodo respectivo
  wsrep_node_name = "bdd-nodo01"
  wsrep_sst_method = rsync
  ```
* **Verificación**:
  * `SHOW STATUS LIKE 'wsrep_cluster_size';` devuelve `3`.
  * `SHOW STATUS LIKE 'wsrep_cluster_status';` devuelve `Primary`.
  * `SHOW STATUS LIKE 'wsrep_local_state_comment';` devuelve `Synced`.
  * Al intentar actualizar la misma fila simultáneamente en dos nodos, el nodo perdedor realiza un rollback automático y lanza un error de deadlock (`Deadlock found when trying to get lock`). Snapshot: `fase11-completa`.

### Fase 12 — Particionamiento de Tablas en MariaDB
* **Objetivo**: Demostrar los 4 tipos de particionamiento nativo de MariaDB (RANGE, LIST, HASH, KEY) en el esquema `lab_particiones` sobre `bdd-nodo01`, como base conceptual para la fragmentación distribuida.
* **Conceptos clave**: Particionamiento nativo vs. fragmentación distribuida, poda de particiones (partition pruning), claves primarias compuestas, incompatibilidad con FK.
* **Comandos clave (`bdd-nodo01`)**:
  ```sql
  CREATE TABLE ventas_range (
    id INT, producto VARCHAR(50), cantidad INT, fecha DATE
  ) PARTITION BY RANGE (YEAR(fecha)) (
    PARTITION p_antes2024 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
  );
  ```
  ```sql
  SELECT TABLE_NAME, PARTITION_NAME, TABLE_ROWS
  FROM INFORMATION_SCHEMA.PARTITIONS
  WHERE TABLE_SCHEMA = 'lab_particiones';
  ```
* **Verificación**: `EXPLAIN SELECT * FROM ventas_range WHERE fecha = '2025-06-15'` muestra `partitions p_2025` (poda). Las filas insertadas con distintas regiones caen en la partición LIST correcta. Snapshot: `fase12-completa`.

### Fase 13 — Fragmentación Horizontal
* **Objetivo**: Crear `bdd-nodo04` (Shard A: Norte/Este) y `bdd-nodo05` (Shard B: Sur/Oeste) como clones enlazados, distribuyendo `clientes`, `pedidos` y `detalle_pedidos` por región.
* **Conceptos clave**: Clon enlazado (linked clone), `mysqldump --where`, fragmentación derivada, co-localización, completitud/disjunción/reconstrucción.
* **Comandos clave**:
  ```bash
  # mysqldump con filtro por región
  mysqldump --where="region IN ('norte','este')" lab_bdd clientes > clientes_shard_a.sql
  mysqldump --where="region IN ('sur','oeste')" lab_bdd clientes > clientes_shard_b.sql
  ```
  ```sql
  -- Reconstrucción vía UNION ALL
  SELECT COUNT(*) FROM (
    SELECT * FROM bdd-nodo04.lab_bdd.clientes
    UNION ALL
    SELECT * FROM bdd-nodo05.lab_bdd.clientes
  ) AS total;
  ```
* **Verificación**: `SELECT region, COUNT(*) FROM clientes GROUP BY region` en cada shard devuelve solo sus regiones. La suma de filas de ambos shards es igual al total original. Snapshot: `fase13-completa`.

### Fase 14 — Fragmentación Vertical
* **Objetivo**: Distribuir `productos` verticalmente entre `nodo04` (columnas básicas) y `nodo05` (columnas de detalle), y provisionar `bdd-nodo06` como coordinador Spider.
* **Conceptos clave**: Fragmentación vertical (completitud/disjunción/reconstrucción por JOIN), Spider Storage Engine, `CREATE SERVER`, `LIST COLUMNS (region)`, poda automática.
* **Comandos clave**:
  ```sql
  -- En nodo06: instalar Spider
  INSTALL SONAME 'ha_spider';
  
  -- Registrar servidores remotos
  CREATE SERVER shard_a FOREIGN DATA WRAPPER mysql
    OPTIONS (HOST '192.168.56.104', DATABASE 'lab_bdd', USER 'lab_admin', PASSWORD 'LabAdmin_2025!');
  
  -- Tabla Spider particionada
  CREATE TABLE clientes (
    id INT, nombre VARCHAR(50), region VARCHAR(10), ...
  ) ENGINE=Spider
  PARTITION BY LIST COLUMNS (region) (
    PARTITION p_norte VALUES IN ('norte') COMMENT = 'srv "shard_a"',
    PARTITION p_este  VALUES IN ('este')  COMMENT = 'srv "shard_a"',
    PARTITION p_sur   VALUES IN ('sur')   COMMENT = 'srv "shard_b"',
    PARTITION p_oeste VALUES IN ('oeste') COMMENT = 'srv "shard_b"'
  );
  ```
* **Verificación**: `SELECT * FROM clientes WHERE region = 'norte'` desde nodo06 muestra solo filas del shard A. `EXPLAIN` confirma poda a `p_norte`. Snapshot: `fase14-completa`.

### Fase 15 — Fragmentación Híbrida
* **Objetivo**: Optimizar consultas distribuidas con índices compuestos, predicate pushdown y proyección de columnas. Crear objetos de negocio que encapsulan la distribución.
* **Conceptos clave**: Fragmentación híbrida inter-tabla, grado de localidad (8 consultas H-1 a H-8), predicate pushdown, proyección de columnas, fan-out de escrituras.
* **Comandos clave**:
  ```sql
  -- Índice compuesto en shards
  CREATE INDEX idx_pedidos_cliente_region ON pedidos(cliente_id, region);
  
  -- Vista de negocio transparente
  CREATE VIEW reporte_pedidos_detallado AS
  SELECT c.nombre, c.region, p.fecha_pedido, dp.cantidad, pr.nombre AS producto
  FROM clientes c
  JOIN pedidos p ON c.id = p.cliente_id
  JOIN detalle_pedidos dp ON p.id = dp.pedido_id
  JOIN v_productos_completo pr ON dp.producto_id = pr.id;
  
  -- Procedimiento regional
  CREATE PROCEDURE consulta_regional(IN p_region VARCHAR(10))
  BEGIN
    SELECT * FROM reporte_pedidos_detallado WHERE region = p_region;
  END;
  ```
* **Verificación**: `CALL consulta_regional('norte')` desde nodo06 devuelve resultados sin que el cliente sepa que los datos están en 4 nodos distintos. Snapshot: `fase15-completa`.

### Fase 16 — Consultas Distribuidas
* **Objetivo**: Formalizar el algoritmo de procesamiento distribuido en 4 fases, implementar semijoin (Bernstein-Chiu), y provisionar `bdd-nodo07` como estación cliente que prueba la transparencia total.
* **Conceptos clave**: Algoritmo de 4 fases (descomposición, localización, optimización global, ejecución), semijoin distribuida, `analizar_consulta()`, estación cliente ligera.
* **Comandos clave**:
  ```sql
  -- Procedimiento de análisis de consulta
  CREATE PROCEDURE analizar_consulta(
    IN p_region VARCHAR(10),
    IN p_detalle BOOLEAN
  )
  BEGIN
    -- Estima fragmentos involucrados, filas esperadas, bytes y grado de localidad
  END;
  
  -- Semijoin manual (Bernstein-Chiu)
  SELECT id FROM nodo04.clientes WHERE region = 'norte';  -- paso 1
  SELECT * FROM nodo04.pedidos WHERE cliente_id IN (...); -- paso 2
  ```
* **Configuración de bdd-cliente (`/etc/hosts`)**:
  ```text
  192.168.56.106 bdd-nodo06
  ```
* **Verificación**: `mysql -h bdd-nodo06 -u app_final -p -e "CALL consulta_regional('sur');"` desde `bdd-nodo07` devuelve datos sin que el cliente conozca la topología interna. Snapshot: `fase16-completa`.

---

## 🤖 Directrices para Agentes de IA (Instrucciones de Contexto Rápido)

Si eres un agente de IA operando en este repositorio, ten en cuenta las siguientes reglas de oro para mantener la consistencia:

1. **Usa siempre `bddadmin`**: Para operaciones SSH, el usuario es `bddadmin`. No uses `vagrant` a menos que sea estrictamente necesario para la inicialización.
2. **Respeta las credenciales**: No inventes contraseñas. Usa siempre `LabAdmin_2025!` para root/admin, `AppUser_2025!` para usuarios de aplicación y `ReplUser_2025!` para replicación.
3. **No alteres los puertos**: En Vagrant, las IPs son estáticas y directas. En Docker, los puertos están mapeados en el host (`3306` para nodo01, `3307` para nodo02, ..., `3311` para nodo06), pero internamente entre contenedores todos usan el puerto estándar `3306`.
4. **Matiz de Galera en Automatización**: La guía académica original (`markdown/Fase 11`) describe la instalación de Galera Cluster. Sin embargo, para simplificar la automatización y ahorrar recursos, los scripts de aprovisionamiento de Vagrant y Docker Compose configuran replicación lógica estándar basada en GTID. Mantén esta simplificación a menos que el usuario pida explícitamente habilitar Galera real.
5. **No modifiques archivos de configuración directamente**: Siempre prefiere crear archivos de configuración con prefijo numérico alto (ej. `99-lab-charset.cnf` o `60-replication.cnf`) bajo `/etc/mysql/mariadb.conf.d/` para evitar colisiones con las configuraciones por defecto del sistema.
