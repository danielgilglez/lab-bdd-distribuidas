Fase 14 — Fragmentación Vertical
| Materia | BDD |     |     |
| ------- | --- | --- | --- |
Continuación directa de la Fase 13. Los cinco nodos del laboratorio tienen sus snapshots
 tomados:   es el maestro de replicación física,
| fase13-completa | bdd-nodo01 |     | bdd-nodo02 |
| --------------- | ---------- | --- | ---------- |
su esclavo con  read_only = ON ,  bdd-nodo03  el nodo multi-maestro,  bdd-nodo04
almacena
el fragmento horizontal A (regiones norte y este de  clientes ,  pedidos  y
detalle_pedidos ) y  bdd-nodo05  el fragmento horizontal B (regiones sur y oeste).
Ambos shards tienen además el catálogo completo de  productos  como tabla temporal
íntegra.
En esta fase se realizan dos tareas complementarias: los diez productos se distribuyen
verticalmente entre nodo04 ( V_productos_basico , columnas operacionales) y nodo05
| ( , columnas de detalle de gran volumen), y se crea  |     |     |            |
| ---------------------------------------------------- | --- | --- | ---------- |
| V_productos_detalle                                  |     |     | bdd-nodo06 |
como coordinador de consultas distribuidas usando el motor Spider de MariaDB.
Al finalizar, el cliente puede conectarse a nodo06 y ejecutar consultas globales
—accediendo
a datos físicamente distribuidos en nodo04 y nodo05— sin conocer la
distribución subyacente:
primera demostración completa de transparencia de fragmentación y transparencia de
ubicación en el laboratorio.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Crear y poblar los dos fragmentos verticales de  productos  en los nodos de sharding
aplicando el plan definido en el Documento de Diseño Distribuido (DDD) de la Fase  y
verificando las tres condiciones de correctitud completitud disjunción de columnas no
| clave y reconstrucción por  |    |     |     |
| --------------------------- | --- | --- | --- |
JOIN
 Explicar qué es el motor Spider de MariaDB cómo actúa como proxy transparente hacia
tablas remotas y en qué se diferencia del motor  FEDERATED  (descontinuado)
 Provisionar  bdd-nodo06  como clon enlazado del snapshot  fase07-completa  de nodo
| configurar su hostname IP estática  |                |  y            |    |
| ------------------------------------ | -------------- | ------------- | --- |
|                                      | 192.168.56.106 | server_id = 6 |     |
1

 Instalar y habilitar el plugin Spider con INSTALL SONAME 'ha_spider'  verificando que
el motor queda ACTIVE en information_schema.PLUGINS y que sus tablas de sistema
mysql.spider_* existen correctamente
 Registrar los nodos remotos con CREATE SERVER  explicando las ventajas de este enfoque
frente a incrustar credenciales directamente en el COMMENT de cada tabla Spider
 Crear tablas Spider particionadas para clientes y pedidos usando
PARTITION BY LIST COLUMNS (region)  conectando el concepto de poda de particiones
aprendido en la Fase  con el enrutamiento automático hacia el shard correcto
 Diseñar y justificar la solución para detalle_pedidos (sin columna region ) usando
dos tablas Spider simples más una VIEW UNION ALL  explicando por qué no es posible
usar
PARTITION BY LIST COLUMNS para esta tabla
 Crear las tablas Spider para los fragmentos verticales de productos y la VIEW productos
que los reconstruye por JOIN  logrando transparencia de fragmentación vertical
 Ejecutar y analizar consultas distribuidas desde nodo que demuestren poda
de particiones
(acceso a un solo shard) UNION ALL implícito (ambos shards) y JOIN distribuido entre
fragmentos verticales
 Tomar el snapshot fase14-completa en los seis nodos del laboratorio
B. Conceptos teóricos necesarios
1. Revisión: fragmentación vertical y condiciones de correctitud.
La fragmentación vertical divide las columnas de una relación R en proyecciones disjuntas,
cada una acompañada de la clave primaria:
Text
Vᵢ = π(Cᵢ ∪ {PK})(R)
Las tres condiciones de correctitud verificadas analíticamente en la Fase 9 se trasladan ahora
a nodos físicos separados:
2

• Completitud todos los productos deben existir en  V_basico  (nodo) y en
V_detalle  (nodo) ninguna fila puede perderse en ninguno de los dos fragmentos
• Disjunción de columnas no clave  {nombre, categoria, precio, stock,
fecha_creacion}
∩  {descripcion, ficha_tecnica, imagen_url, peso_kg}  = ∅ La PK ( id ) y la clave
alternativa ( sku ) se duplican intencionalmente en ambos fragmentos para permitir
| la reconstrucción mediante  | JOIN |    |
| --------------------------- | ---- | --- |
• Reconstrucción  JOIN  por  id  entre los dos fragmentos reproduce la relación
| productos  completa sin pérdida de atributos |     |     |
| --------------------------------------------- | --- | --- |
2. El motor Spider de MariaDB.
Spider es un motor de almacenamiento nativo de MariaDB —integrado desde la versión 10.0,
estable desde 10.3— que permite crear tablas cuyos datos residen en uno o varios servidores
MariaDB o MySQL remotos. Para el cliente, las tablas Spider son indistinguibles de tablas
InnoDB locales: mismo SQL estándar, mismos tipos de datos, mismas operaciones DML.
| Característica | FEDERATED  | Spider |
| -------------- | ---------- | ------ |
(descontinuado)
| Particionamient  | No  | Sí (RANGE LIST  |
| ---------------- | --- | ----------------- |
| o entre nodos    |     | HASH KEY)        |
| JOIN distribuido | No  | Sí (coordinador   |
recombina
resultados)
| Transacciones  | No  | Soporte parcial |
| -------------- | --- | --------------- |
XA
| Mantenimiento   | Abandonado | Activo en       |
| --------------- | ---------- | --------------- |
| activo          |            | MariaDB x    |
| Tablas de       | No         | Sí              |
| sistema propias |            | ( mysql.spider_ |
)
*
Internamente, Spider traduce el SQL del cliente en llamadas TCP al servidor remoto usando el
protocolo binario de MariaDB. Para un  SELECT  con filtro sobre la columna de
particionamiento, Spider envía la subconsulta únicamente al shard relevante (poda remota).
Para un  SELECT  sin filtro, consulta todos los shards y combina los resultados en el
| coordinador mediante  | .   |     |
| --------------------- | --- | --- |
UNION ALL
3

3. Modos de operación de Spider en este laboratorio.
| Modo | Descripción | Aplicación en  |     |
| ---- | ----------- | -------------- | --- |
Fase 
| Simple | Una tabla Spider  | v_productos_ba |     |
| ------ | ----------------- | -------------- | --- |
|        | apunta a una      | sico           |    |
sola tabla
v_productos_de
remota en
|     |     | talle |    |
| --- | --- | ----- | --- |
un nodo
spider_detalle
|     |     | _nodo04 |    |
| --- | --- | ------- | --- |
spider_detalle
_nodo05
| Horizontal | PARTITION BY    | clientes        |    |
| ---------- | --------------- | --------------- | --- |
|            | LIST COLUMNS    |   pedidos       |     |
|            | enruta filas    | (particionadas  |     |
|            | según el valor  | por  region     | )   |
de la columna
de partición
hacia distintos
shards
| Vertical | Dos tablas      | VIEW      |     |
| -------- | --------------- | --------- | --- |
|          | Spider simples  | productos |  =  |
más una
VIEW  JOIN de

|     | JOIN          | V_basico y  |     |
| --- | ------------- | ----------- | --- |
|     | reconstruyen  | V_detalle   |     |
columnas
distribuidas
entre dos nodos
| 4.  | : definición de conexiones remotas reutilizables. |     |     |
| --- | ------------------------------------------------- | --- | --- |
CREATE SERVER
CREATE SERVER  almacena un conjunto de parámetros de conexión bajo un nombre simbólico.
Las tablas Spider referencian ese nombre en el  COMMENT  en lugar de repetir IP, puerto,
usuario y contraseña en cada definición:
4

SQL
CREATE SERVER srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (
HOST '192.168.56.104',
PORT 3306,
DATABASE 'lab_bdd',
USER 'spider_user',
PASSWORD 'Spider_2025!'
);
-- Uso posterior en tabla Spider:
CREATE TABLE t (...) ENGINE = SPIDER
COMMENT = 'server "srv_nodo04", table "nombre_tabla_remota"';
Los servidores se persisten en mysql.servers y se eliminan con DROP SERVER nombre .
5. Tablas Spider particionadas: conexión con la Fase 12.
Las tablas Spider clientes y pedidos del coordinador usan PARTITION BY LIST COLUMNS
(region) . El motor aplica poda de particiones remota: ante WHERE region = 'norte' ,
Spider envía la subconsulta solo al shard que contiene esa región. Este es exactamente el
mismo mecanismo de la Fase 12 extendido a nodos físicamente distintos.
La clave primaria de la tabla Spider particionada debe incluir la columna de particionamiento,
requerimiento idéntico al del particionamiento nativo de la Fase 12:
SQL
PRIMARY KEY (id, region) -- region obligatoria en PK para
Spider particionado
La tabla remota en nodo04 puede mantener PRIMARY KEY (id) sin cambios; esta
discrepancia
en la definición de PK es permitida por Spider y no genera conflictos en la práctica.
6. Por qué detalle_pedidos no puede usar PARTITION BY LIST COLUMNS (region) .
5

detalle_pedidos no tiene columna region . Spider necesita que la columna de
particionamiento
exista en la tabla para poder aplicar la poda. Sin region , no es posible usar el mismo
esquema de particionamiento que clientes y pedidos . La solución adoptada es crear
una tabla Spider simple por shard y unirlas mediante una VIEW UNION ALL , que Spider
resuelve consultando ambos nodos y combinando los resultados en el coordinador.
7. Transparencia de distribución lograda al finalizar la fase.
Tipo de Mecanismo Primera fase de
transparencia implementado verificación
Fragmentación El cliente Fase 
consulta
clientes 
productos  etc
sin saber que
los datos están
divididos entre
nodos
Ubicación El cliente Fase 
conecta siempre
a
192.168.56.10
6  ignora la
existencia de
nodo y
nodo
Replicación Maestro- Fase 
esclavo
transparente
para el cliente
de nodo
Concurrencia MVCC de Fase 
InnoDB pruebas
con
transacciones
concurrentes
6

C. Prerrequisitos
Antes de iniciar esta fase, verificar que se cumplen todos los puntos siguientes:
Estado de las máquinas virtuales:
7

| Nodo       | Snapshot  | Estado funcional  |
| ---------- | --------- | ----------------- |
|            | requerido | esperado          |
| bdd-nodo01 | fase13-   | MAESTRO de        |
|            | completa  | replicación      |
lab_bdd  con
///
filas
ESCLAVO
| bdd-nodo02 | fase13- |     |
| ---------- | ------- | --- |
read_only =
completa
ON
| bdd-nodo03 | fase13-  | MULTI-    |
| ---------- | -------- | --------- |
|            | completa | MAESTRO  |
réplica
bidireccional
con nodo
| bdd-nodo04 | fase13-  | SHARD-A:       |
| ---------- | -------- | -------------- |
|            | completa | clientes  (  |
filas
norte+este)
pedidos  ()
detalle_pedido
s  (~)
productos  (
completo)
server_id =
4   bind-
address =
0.0.0.0
SHARD-B:
| bdd-nodo05 | fase13- |     |
| ---------- | ------- | --- |
 (
|     | completa | clientes |
| --- | -------- | -------- |
filas sur+oeste)
 ()
pedidos
detalle_pedido
 (~)
s
 (
productos
completo)
server_id =

5 bind-
address =
0.0.0.0
8

bdd-nodo06 — No existe aún
se crea en
esta fase
Conocimiento técnico requerido:
• Fragmentación vertical columnas operacionales vs columnas de detalle ( V_basico /
V_detalle )
y sus predicados de correctitud tal como se diseñaron en la Fase  (DDD sección )
• Particionamiento nativo LIST COLUMNS de MariaDB (Fase ): los mismos predicados y el
mismo
mecanismo de poda de particiones se usan ahora en tablas Spider del coordinador
• Creación de clones enlazados de VirtualBox y reconfiguración de hostname e IP (Fase 
pasos D–D)
Recursos de host necesarios:
• Al menos  GB de RAM adicional libre para nodo (  MB asignados)
• Al menos  GB de disco libre para el disco delta del clon enlazado
• La estructura C:\LabBDD\ con sus subcarpetas (creada en la Fase )
Archivos de referencia:
• C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md — secciones 
(fragmentación horizontal)
y  (fragmentación vertical) son la especificación técnica que guía esta fase
9

D. Procedimiento paso a paso
Arquitectura al inicio de la Fase 14
Text
bdd-nodo01 [MAESTRO | 192.168.56.101] lab_bdd completo
(20/10/20/36 filas)
bdd-nodo02 [ESCLAVO | 192.168.56.102] lab_bdd réplica, read_only = ON
bdd-nodo03 [MULTI-M. | 192.168.56.103] lab_bdd réplica bidireccional
bdd-nodo04 [SHARD-A | 192.168.56.104] clientes(10)
pedidos(10) detalle(~18)
productos(10, completo
— temporal)
bdd-nodo05 [SHARD-B | 192.168.56.105] clientes(10)
pedidos(10) detalle(~18)
productos(10, completo
— temporal)
[bdd-nodo06 NO EXISTE AÚN]
10

Arquitectura al finalizar la Fase 14
Text
bdd-nodo04 [SHARD-A | 192.168.56.104]
+ v_productos_basico (id, sku, nombre, categoria, precio,
stock, fecha_creacion)
bdd-nodo05 [SHARD-B | 192.168.56.105]
+ v_productos_detalle (id, sku, descripcion, ficha_tecnica,
imagen_url, peso_kg)
bdd-nodo06 [COORDINADOR | 192.168.56.106] server_id=6, log_bin=OFF,
Spider ACTIVE
lab_bdd (solo metadatos Spider — sin filas de datos de negocio):
┌─ clientes [SPIDER PARTITION LIST region
→ nodo04/nodo05]
├─ pedidos [SPIDER PARTITION LIST region
→ nodo04/nodo05]
├─ spider_detalle_nodo04 [SPIDER simple
→ nodo04.detalle_pedidos]
├─ spider_detalle_nodo05 [SPIDER simple
→ nodo05.detalle_pedidos]
├─ v_productos_basico [SPIDER simple →
nodo04.v_productos_basico]
├─ v_productos_detalle [SPIDER simple →
nodo05.v_productos_detalle]
├─ VIEW detalle_pedidos [UNION ALL spider_detalle_nodo04
+ nodo05]
└─ VIEW productos [JOIN v_productos_basico
⋈ v_productos_detalle]
Paso 1 — Iniciar nodo04 y nodo05; verificar el estado heredado de la Fase 13
(conteos de filas, bind-address , server_id ).
Paso 2 — Crear el usuario spider_user en nodo04 y en nodo05, restringido
a la IP futura de nodo06 ( 192.168.56.106 ).
Paso 3 — Crear la tabla v_productos_basico en nodo04 con las columnas
operacionales y poblarla desde la tabla productos completa que ya existe en ese nodo.
Paso 4 — Crear la tabla v_productos_detalle en nodo05 con las columnas de detalle
y poblarla desde la tabla productos completa en ese nodo.
11

Paso 5 — Verificar las tres condiciones de correctitud de la fragmentación vertical
en nodo04 y nodo05 (completitud, disjunción de columnas, reconstrucción simulada).
Paso 6 — Apagar nodo04 y nodo05 antes de crear nodo06, para evitar conflicto de IP
cuando el clon arranque temporalmente con la dirección  192.168.56.101 .
| Paso 7 — Crear  |                 |  como clon enlazado de    |            |  tomado desde el |     |
| --------------- | --------------- | ------------------------- | ---------- | ---------------- | --- |
|                 | bdd-nodo06      |                           | bdd-nodo01 |                  |     |
| snapshot        | fase07-completa |  (MariaDB instalado, sin  | lab_bdd ). |                  |     |
Paso 8 — Arrancar solo nodo06, configurar hostname ( ), IP estática
bdd-nodo06
( 192.168.56.106 ) y  /etc/hosts  con las entradas de todos los nodos del laboratorio.
Paso 9 — Crear el archivo de configuración de MariaDB del coordinador:
|     | ,   | ,   | ,   |     | .   |
| --- | --- | --- | --- | --- | --- |
server_id = 6 log_bin = OFF bind-address = 0.0.0.0 skip_name_resolve = ON
Desactivar cualquier archivo de configuración de replicación heredado del clon.
Paso 10 — Instalar el motor Spider en nodo06 con  INSTALL SONAME 'ha_spider' .
Verificar que el plugin queda   y que las tablas de sistema
|     |     | ACTIVE |     | mysql.spider_* |     |
| --- | --- | ------ | --- | -------------- | --- |
fueron creadas.
Paso 11 — Arrancar nodo04 y nodo05 (ya en sus IPs  .104  y  .105 ).
Verificar conectividad TCP desde nodo06 hacia ambos shards en el puerto 3306.
Paso 12 — Registrar los servidores remotos en nodo06 con  CREATE SERVER srv_nodo04
| y   |     | .   |     |     |     |
| --- | --- | --- | --- | --- | --- |
CREATE SERVER srv_nodo05
Paso 13 — Crear la base de datos  lab_bdd  en nodo06 y las tablas Spider para los
fragmentos horizontales:  clientes  y  pedidos  (particionadas por  region ), y los dos
pares de tablas Spider para  detalle_pedidos  más su  VIEW UNION ALL .
Paso 14 — Crear las tablas Spider  v_productos_basico  y  v_productos_detalle  en
| nodo06 y la  |                |  que las reconstruye por  | .    |     |     |
| ------------ | -------------- | ------------------------- | ---- | --- | --- |
|              | VIEW productos |                           | JOIN |     |     |
Paso 15 — Ejecutar las consultas de verificación distribuida desde nodo06: acceso
particionado a  clientes  (poda activa), ficha completa de producto (JOIN distribuido
vertical) y consulta híbrida que combina fragmentación horizontal y vertical.
Paso 16 — Apagar todos los nodos y tomar el snapshot  fase14-completa  en los seis
nodos del laboratorio.
12

E. Comandos completos
Los bloques (host) se ejecutan en PowerShell en Windows. Los bloques (VM — nodoXX)
se ejecutan en una sesión SSH al nodo indicado. Los bloques SQL dentro de sudo mariadb
se ejecutan en el prompt del motor MariaDB.
E.1 Iniciar nodo04 y nodo05; verificar el estado de la Fase 13 (host)
PowerShell
VBoxManage startvm "bdd-nodo04" --type headless
VBoxManage startvm "bdd-nodo05" --type headless
Start-Sleep -Seconds 35
Conectarse a ambos nodos:
PowerShell
# Terminal 1 — nodo04
ssh bddadmin@192.168.56.104
# Terminal 2 — nodo05
ssh bddadmin@192.168.56.105
Verificar el estado en (VM — nodo04):
13

Bash
sudo mariadb lab_bdd << 'EOF'
-- Conteos heredados de la Fase 13
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM detalle_pedidos
UNION ALL
SELECT 'productos', COUNT(*) FROM productos;
-- Solo deben aparecer las regiones del fragmento A
SELECT DISTINCT region AS regiones_presentes FROM clientes ORDER BY region;
EOF
# Verificar parámetros clave de MariaDB
sudo mariadb -e "SHOW VARIABLES LIKE 'bind_address';"
sudo mariadb -e "SHOW VARIABLES LIKE 'server_id';"
Salida esperada en nodo04:
Text
clientes | 10
pedidos | 10
detalle_pedidos | ~18
productos | 10
regiones_presentes: este, norte
bind_address: 0.0.0.0
server_id: 4
Repetir en nodo05 esperando sur, oeste y server_id = 5 .
Si bind_address devuelve 127.0.0.1 en algún shard, corregirlo antes de continuar:
14

Bash
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
/etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
sudo mariadb -e "SHOW VARIABLES LIKE 'bind_address';"
E.2 Crear el usuario spider_user en nodo04 y nodo05 (VM — nodo04 y
nodo05)
Ejecutar en nodo04:
Bash
sudo mariadb << 'EOF'
-- ----------------------------------------------------------------
-- Usuario de acceso remoto para Spider.
-- Host: IP exacta de bdd-nodo06 (principio de mínimo privilegio).
-- Privilegios: SELECT + escritura sobre lab_bdd.
-- ----------------------------------------------------------------
CREATE USER IF NOT EXISTS 'spider_user'@'192.168.56.106'
IDENTIFIED BY 'Spider_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE
ON lab_bdd.*
TO 'spider_user'@'192.168.56.106';
FLUSH PRIVILEGES;
-- Verificar
SELECT User, Host FROM mysql.user WHERE User = 'spider_user';
SHOW GRANTS FOR 'spider_user'@'192.168.56.106';
EOF
Ejecutar el mismo bloque en nodo05 sin modificaciones.
15

E.3 Crear v_productos_basico en nodo04 (VM — nodo04)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- FRAGMENTO VERTICAL A — Columnas operacionales (alta frecuencia)
-- Nodo destino: bdd-nodo04 (192.168.56.104)
-- Plan DDD Fase 9: id*, sku, nombre, categoria,
-- precio, stock, fecha_creacion
-- Uso esperado: listados, búsquedas, cálculo de precios
-- ============================================================
CREATE TABLE IF NOT EXISTS v_productos_basico (
id INT NOT NULL AUTO_INCREMENT,
sku VARCHAR(50) NOT NULL,
nombre VARCHAR(200) NOT NULL,
categoria VARCHAR(100),
precio DECIMAL(10,2) NOT NULL,
stock INT DEFAULT 0,
fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (id),
UNIQUE KEY uq_sku (sku)
) ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci
COMMENT = 'Fragmento vertical basico de productos — Fase 14';
-- Poblar desde la tabla productos completa existente en este nodo
-- (cargada íntegramente como catálogo temporal en la Fase 13)
INSERT INTO v_productos_basico
(id, sku, nombre, categoria, precio, stock, fecha_creacion)
SELECT id, sku, nombre, categoria, precio, stock, fecha_creacion
FROM productos;
-- Verificar la carga
SELECT 'Filas en v_productos_basico' AS metrica, COUNT(*) AS valor
FROM v_productos_basico;
-- Vista previa
SELECT id, sku, nombre, categoria, precio, stock
FROM v_productos_basico
ORDER BY id;
EOF
16

E.4 Crear v_productos_detalle en nodo05 (VM — nodo05)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- FRAGMENTO VERTICAL B — Columnas de detalle (baja frecuencia)
-- Nodo destino: bdd-nodo05 (192.168.56.105)
-- Plan DDD Fase 9: id*, sku, descripcion,
-- ficha_tecnica, imagen_url, peso_kg
-- Uso esperado: pantalla de ficha completa de producto
-- ============================================================
CREATE TABLE IF NOT EXISTS v_productos_detalle (
id INT NOT NULL,
sku VARCHAR(50) NOT NULL,
descripcion TEXT,
ficha_tecnica TEXT,
imagen_url VARCHAR(500),
peso_kg DECIMAL(8,3),
PRIMARY KEY (id),
KEY idx_sku (sku)
) ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COLLATE = utf8mb4_unicode_ci
COMMENT = 'Fragmento vertical detalle de productos — Fase 14';
-- Poblar desde la tabla productos completa en este nodo
INSERT INTO v_productos_detalle
(id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg)
SELECT id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos;
-- Verificar la carga
SELECT 'Filas en v_productos_detalle' AS metrica, COUNT(*) AS valor
FROM v_productos_detalle;
-- Vista previa con truncado de columnas TEXT
SELECT id, sku,
LEFT(descripcion, 50) AS descripcion_preview,
LEFT(ficha_tecnica, 50) AS ficha_preview,
imagen_url,
peso_kg
FROM v_productos_detalle
ORDER BY id;
EOF
17

E.5 Verificar correctitud de la fragmentación vertical (VM — nodo04
y nodo05)
Ejecutar en nodo04:
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- CONDICIÓN 1: COMPLETITUD
-- Todos los productos originales deben estar en v_productos_basico.
-- ============================================================
SELECT 'Completitud V_productos_basico' AS condicion,
(SELECT COUNT(*) FROM productos) AS total_original,
COUNT(*) AS filas_en_fragmento,
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA'
END AS resultado
FROM v_productos_basico;
-- ============================================================
-- CONDICIÓN 2: DISJUNCIÓN DE COLUMNAS NO CLAVE
-- Las columnas TEXT de detalle NO deben existir en V_basico.
-- ============================================================
SELECT 'Disjunción columnas V_productos_basico' AS condicion,
CASE WHEN COUNT(*) = 0
THEN 'OK — sin columnas de detalle'
ELSE CONCAT('FALLA — columnas encontradas: ',
GROUP_CONCAT(COLUMN_NAME))
END AS resultado
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
AND TABLE_NAME = 'v_productos_basico'
AND COLUMN_NAME IN ('descripcion','ficha_tecnica','imagen_url','peso_kg');
EOF
Ejecutar en nodo05:
18

Bash
sudo mariadb lab_bdd << 'EOF'
-- COMPLETITUD de V_detalle
SELECT 'Completitud V_productos_detalle' AS condicion,
(SELECT COUNT(*) FROM productos) AS total_original,
COUNT(*) AS filas_en_fragmento,
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA'
END AS resultado
FROM v_productos_detalle;
-- DISJUNCIÓN: columnas operacionales NO deben estar en V_detalle
SELECT 'Disjunción columnas V_productos_detalle' AS condicion,
CASE WHEN COUNT(*) = 0
THEN 'OK — sin columnas operacionales'
ELSE CONCAT('FALLA — columnas encontradas: ',
GROUP_CONCAT(COLUMN_NAME))
END AS resultado
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
AND TABLE_NAME = 'v_productos_detalle'
AND COLUMN_NAME IN
('nombre','categoria','precio','stock','fecha_creacion');
-- RECONSTRUCCIÓN SIMULADA (local en nodo05):
-- JOIN entre v_productos_detalle y la tabla productos completa.
-- Verifica que todos los IDs tienen contraparte.
SELECT 'Reconstrucción (IDs coincidentes)' AS condicion,
(SELECT COUNT(*) FROM productos) AS total_original,
COUNT(*) AS filas_reconstruidas,
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA'
END AS resultado
FROM v_productos_detalle d
JOIN productos p ON p.id = d.id;
EOF
Todos los resultados deben mostrar OK antes de continuar.
19

E.6 Apagar nodo04 y nodo05 (host)
El clon de nodo06 arrancará temporalmente con la IP 192.168.56.101 heredada del snapshot
de nodo01. Para evitar conflictos ARP, todos los nodos deben estar apagados:
Bash
# En la sesión SSH de nodo04
sudo poweroff
# En la sesión SSH de nodo05
sudo poweroff
Confirmar desde el host:
PowerShell
VBoxManage list runningvms
# La salida debe estar vacía
E.7 Crear bdd-nodo06 como clon enlazado (host)
PowerShell
# Se clona desde fase07-completa de nodo01:
# MariaDB 10.11 instalado + utf8mb4 activo, SIN lab_bdd.
# Esta es la base más limpia para un coordinador que no almacena
# datos de negocio propios, solo metadatos Spider.
VBoxManage clonevm "bdd-nodo01" `
--snapshot "fase07-completa" `
--options linked `
--name "bdd-nodo06" `
--basefolder "C:\LabBDD\VMs" `
--register
VBoxManage modifyvm "bdd-nodo06" `
--description "COORDINADOR Spider. Sin datos de negocio. IP 192.168.56.106.
server_id=6. Fase 14."
# Confirmar registro
VBoxManage showvminfo "bdd-nodo06" | findstr /I "Name State Memory"
Arrancar solo nodo06 (los demás están apagados — sin conflicto de IP):
20

PowerShell
VBoxManage startvm "bdd-nodo06" --type headless
Start-Sleep -Seconds 35
# El clon tiene temporalmente la IP de nodo01 (192.168.56.101)
ssh bddadmin@192.168.56.101
E.8 Configurar hostname, IP y /etc/hosts en nodo06 (VM — nodo06)
Bash
# ── 1. Cambiar el hostname ────────────────────────────────────
sudo hostnamectl set-hostname bdd-nodo06
sudo sed -i 's/bdd-nodo01/bdd-nodo06/g' /etc/hosts
hostname
# Esperado: bdd-nodo06
Bash
# ── 2. Cambiar la IP de .101 a .106 ──────────────────────────
NETPLAN_FILE=$(ls /etc/netplan/*.yaml | head -1)
echo "Archivo Netplan detectado: $NETPLAN_FILE"
# Verificar contenido antes de editar
cat "$NETPLAN_FILE"
# Sustituir la dirección IP
sudo sed -i 's/192\.168\.56\.101/192.168.56.106/g' "$NETPLAN_FILE"
# Confirmar el cambio
grep "192.168" "$NETPLAN_FILE"
# Aplicar — la sesión SSH se interrumpe en este punto
sudo netplan apply
La sesión SSH se pierde al cambiar la IP. Reconectar desde el host:
PowerShell
Start-Sleep -Seconds 8
ssh bddadmin@192.168.56.106
21

Bash
# ── 3. Verificar la nueva IP ──────────────────────────────────
ip addr show | grep "192.168.56"
# Esperado: inet 192.168.56.106/24
ping -c 2 192.168.56.1 # host Windows — debe responder
Bash
# ── 4. Regenerar claves SSH (el clon heredó las de nodo01) ───
sudo rm -f /etc/ssh/ssh_host_*
sudo ssh-keygen -A
sudo systemctl restart ssh
echo "Nuevas claves SSH generadas:"
ls /etc/ssh/ssh_host_*.pub
Bash
# ── 5. Registrar todos los nodos en /etc/hosts ────────────────
sudo tee -a /etc/hosts > /dev/null << 'EOF'
# Laboratorio BDD — nodos del cluster
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
192.168.56.103 bdd-nodo03
192.168.56.104 bdd-nodo04
192.168.56.105 bdd-nodo05
192.168.56.106 bdd-nodo06
EOF
cat /etc/hosts
22

E.9 Configurar MariaDB en nodo06 (VM — nodo06)
Bash
# Desactivar archivos de configuración de replicación heredados del clon
for f in /etc/mysql/mariadb.conf.d/60-replication*.cnf; do
[ -f "$f" ] && sudo mv "$f" "${f}.bak" && echo "Desactivado: $f"
done
# Si se hereda bind-address = 127.0.0.1 en 50-server.cnf, corregirlo
sudo sed -i \
's/^bind-address[](:space:)*=.*/bind-address = 0.0.0.0/' \
/etc/mysql/mariadb.conf.d/50-server.cnf
# Crear el archivo de configuración del coordinador
sudo tee /etc/mysql/mariadb.conf.d/60-coordinador.cnf > /dev/null << 'EOF'
# ===========================================================
# Configuración del coordinador Spider — bdd-nodo06
# IP: 192.168.56.106 | server_id: 6
# Fase 14 del Laboratorio BDD.
# ===========================================================
[mariadb]
# Identificación única del nodo en el ecosistema
server_id = 6
# El coordinador NO replica hacia otros nodos
# y NO actúa como esclavo de ningún maestro
log_bin = OFF
skip_slave_start = ON
# Sin restricción de solo lectura: el coordinador acepta escrituras
read_only = OFF
# Aceptar conexiones desde cualquier interfaz de la red Host-Only
bind-address = 0.0.0.0
# Requerido por Spider: evitar resolución DNS que cause timeouts
skip_name_resolve = ON
EOF
Reiniciar MariaDB y verificar:
23

Bash
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager -l
sudo mariadb << 'EOF'
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'read_only';
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'skip_name_resolve';
EOF
Salida esperada:
Text
server_id → 6
log_bin → OFF
read_only → OFF
bind_address → 0.0.0.0
skip_name_resolve → ON
24

E.10 Instalar y habilitar el motor Spider (VM — nodo06)
Bash
sudo mariadb << 'EOF'
-- ----------------------------------------------------------------
-- Instalar el plugin Spider.
-- INSTALL SONAME carga ha_spider.so dinámicamente y crea las
-- tablas de sistema necesarias en la base de datos mysql.
-- En MariaDB 10.11 el plugin está incluido en el paquete base.
-- ----------------------------------------------------------------
INSTALL SONAME 'ha_spider';
-- Verificar que Spider quedó activo
SELECT PLUGIN_NAME,
PLUGIN_VERSION,
PLUGIN_STATUS,
PLUGIN_TYPE
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'SPIDER';
-- Las tablas de sistema deben existir en mysql
SHOW TABLES IN mysql LIKE 'spider%';
-- Confirmar que Spider aparece como motor disponible
SELECT ENGINE, SUPPORT
FROM information_schema.ENGINES
WHERE ENGINE = 'SPIDER';
EOF
Salida esperada:
Text
PLUGIN_NAME PLUGIN_STATUS PLUGIN_TYPE
SPIDER ACTIVE STORAGE ENGINE
Tablas spider* en mysql:
spider_link_failed_log spider_link_mon_servers spider_tables
spider_xa spider_xa_failed_log spider_xa_member
ENGINE SUPPORT
SPIDER YES
Si PLUGIN_STATUS es DISABLED o la instalación falla con ERROR 1126 :
25

Bash
# Instalar el paquete del plugin desde apt
sudo apt-get update && sudo apt-get install -y mariadb-plugin-spider
# Reintentar la instalación en MariaDB
sudo mariadb -e "INSTALL SONAME 'ha_spider';"
# Si las tablas de sistema no se crearon automáticamente:
SPIDER_SQL=$(find /usr/share/mysql* -name "install_spider.sql" 2>/dev/null |
head -1)
[ -n "$SPIDER_SQL" ] && sudo mariadb < "$SPIDER_SQL" && echo
"Script ejecutado."
E.11 Arrancar nodo04 y nodo05; verificar conectividad (host + VM)
PowerShell
# Con nodo06 ya en .106, arrancar los shards sin conflicto de IP
VBoxManage startvm "bdd-nodo04" --type headless
VBoxManage startvm "bdd-nodo05" --type headless
Start-Sleep -Seconds 35
Verificar conectividad TCP desde nodo06 antes de crear tablas Spider:
Bash
# En nodo06 — verificar acceso a nodo04
mysql -h 192.168.56.104 -P 3306 \
-u spider_user -p'Spider_2025!' \
-e "SELECT 'nodo04 accesible' AS estado, @@hostname AS host,
@@server_id AS srv_id;" 2>&1
# Verificar acceso a nodo05
mysql -h 192.168.56.105 -P 3306 \
-u spider_user -p'Spider_2025!' \
-e "SELECT 'nodo05 accesible' AS estado, @@hostname AS host,
@@server_id AS srv_id;" 2>&1
Salida esperada para cada nodo:
26

Text
+------------------+------------+--------+
| estado | host | srv_id |
+------------------+------------+--------+
| nodo04 accesible | bdd-nodo04 | 4 |
+------------------+------------+--------+
Si alguno devuelve ERROR 2003 , revisar la sección G antes de continuar.
27

E.12 Registrar los servidores remotos con CREATE SERVER (VM — nodo06)
Bash
sudo mariadb << 'EOF'
-- ================================================================
-- SERVIDORES REMOTOS
-- Las credenciales se almacenan una sola vez en mysql.servers.
-- Las tablas Spider referencian solo el nombre del servidor,
-- manteniendo el COMMENT limpio y evitando repetición.
-- ================================================================
CREATE SERVER IF NOT EXISTS srv_nodo04
FOREIGN DATA WRAPPER mysql
OPTIONS (
HOST '192.168.56.104',
PORT 3306,
DATABASE 'lab_bdd',
USER 'spider_user',
PASSWORD 'Spider_2025!'
);
CREATE SERVER IF NOT EXISTS srv_nodo05
FOREIGN DATA WRAPPER mysql
OPTIONS (
HOST '192.168.56.105',
PORT 3306,
DATABASE 'lab_bdd',
USER 'spider_user',
PASSWORD 'Spider_2025!'
);
-- Verificar que ambos servidores quedaron registrados
SELECT Server_name AS servidor,
Host AS ip,
Db AS base_datos,
Username AS usuario,
Port AS puerto
FROM mysql.servers
ORDER BY Server_name;
EOF
Resultado esperado: 2 filas con srv_nodo04 ( .104 ) y srv_nodo05 ( .105 ).
28

E.13 Crear lab_bdd y tablas Spider para fragmentos horizontales (VM —
nodo06)
Bash
sudo mariadb << 'EOF'
-- Base de datos del coordinador
-- No contiene filas de datos de negocio; solo definiciones Spider y VIEWs
CREATE DATABASE IF NOT EXISTS lab_bdd
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci
COMMENT 'Coordinador Spider — Fase 14. Metadatos sin datos locales.';
USE lab_bdd;
-- ================================================================
-- TABLA SPIDER: clientes
-- PARTITION BY LIST COLUMNS (region):
-- frag_A (norte, este) → nodo04
-- frag_B (sur, oeste) → nodo05
-- Con WHERE region = 'norte', Spider envía la subconsulta solo a
-- nodo04 (poda remota activa). Sin filtro, consulta ambos y hace
-- UNION ALL de los resultados.
-- PRIMARY KEY (id, region) es obligatoria con PARTITION Spider.
-- ================================================================
CREATE TABLE IF NOT EXISTS clientes (
id INT NOT NULL AUTO_INCREMENT,
nombre VARCHAR(100) NOT NULL,
apellido VARCHAR(100) NOT NULL,
email VARCHAR(150),
telefono VARCHAR(20),
region ENUM('norte','sur','este','oeste') NOT NULL,
ciudad VARCHAR(100),
fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP,
ultima_modificacion DATETIME DEFAULT NULL,
PRIMARY KEY (id, region)
) ENGINE = SPIDER
PARTITION BY LIST COLUMNS (region) (
PARTITION frag_A VALUES IN ('norte', 'este')
COMMENT = 'server "srv_nodo04", table "clientes"',
PARTITION frag_B VALUES IN ('sur', 'oeste')
COMMENT = 'server "srv_nodo05", table "clientes"'
);
-- ================================================================
-- TABLA SPIDER: pedidos
-- Mismo esquema de particionamiento que clientes.
29

-- ================================================================
CREATE TABLE IF NOT EXISTS pedidos (
id INT NOT NULL AUTO_INCREMENT,
cliente_id INT NOT NULL,
region ENUM('norte','sur','este','oeste') NOT NULL,
fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
estado ENUM('pendiente','procesado','enviado',
'entregado','cancelado') DEFAULT 'pendiente',
total DECIMAL(10,2),
PRIMARY KEY (id, region)
) ENGINE = SPIDER
PARTITION BY LIST COLUMNS (region) (
PARTITION frag_A VALUES IN ('norte', 'este')
COMMENT = 'server "srv_nodo04", table "pedidos"',
PARTITION frag_B VALUES IN ('sur', 'oeste')
COMMENT = 'server "srv_nodo05", table "pedidos"'
);
-- ================================================================
-- TABLAS SPIDER para detalle_pedidos
-- detalle_pedidos no tiene columna region: no se puede aplicar
-- PARTITION BY LIST COLUMNS (region) directamente.
-- Solución: tabla Spider simple por shard + VIEW UNION ALL.
-- ================================================================
CREATE TABLE IF NOT EXISTS spider_detalle_nodo04 (
id INT NOT NULL AUTO_INCREMENT,
pedido_id INT NOT NULL,
producto_id INT NOT NULL,
cantidad INT NOT NULL DEFAULT 1,
precio_unitario DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2),
PRIMARY KEY (id)
) ENGINE = SPIDER
COMMENT = 'server "srv_nodo04", table "detalle_pedidos"';
CREATE TABLE IF NOT EXISTS spider_detalle_nodo05 (
id INT NOT NULL AUTO_INCREMENT,
pedido_id INT NOT NULL,
producto_id INT NOT NULL,
cantidad INT NOT NULL DEFAULT 1,
precio_unitario DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2),
PRIMARY KEY (id)
) ENGINE = SPIDER
COMMENT = 'server "srv_nodo05", table "detalle_pedidos"';
-- VIEW que unifica ambos shards de detalle_pedidos
CREATE OR REPLACE VIEW detalle_pedidos AS
30

SELECT * FROM spider_detalle_nodo04
UNION ALL
SELECT * FROM spider_detalle_nodo05;
-- ================================================================
-- VERIFICACIÓN INMEDIATA — fragmentos horizontales desde nodo06
-- ================================================================
SELECT 'clientes (Spider, 2 shards)' AS fuente, COUNT(*) AS filas
FROM clientes
UNION ALL
SELECT 'pedidos (Spider, 2 shards)', COUNT(*)
FROM pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*)
FROM detalle_pedidos;
-- Resultado esperado: 20 / 20 / ~36
EOF
31

E.14 Crear tablas Spider para fragmentos verticales y VIEW productos
(VM — nodo06)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ================================================================
-- TABLA SPIDER: v_productos_basico → nodo04
-- Columnas operacionales. Solo activa nodo04 cuando se consulta.
-- ================================================================
CREATE TABLE IF NOT EXISTS v_productos_basico (
id INT NOT NULL AUTO_INCREMENT,
sku VARCHAR(50) NOT NULL,
nombre VARCHAR(200) NOT NULL,
categoria VARCHAR(100),
precio DECIMAL(10,2) NOT NULL,
stock INT DEFAULT 0,
fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (id),
UNIQUE KEY uq_sku (sku)
) ENGINE = SPIDER
COMMENT = 'server "srv_nodo04", table "v_productos_basico"';
-- ================================================================
-- TABLA SPIDER: v_productos_detalle → nodo05
-- Columnas de detalle (TEXT). Solo activa nodo05 cuando se consulta.
-- ================================================================
CREATE TABLE IF NOT EXISTS v_productos_detalle (
id INT NOT NULL,
sku VARCHAR(50) NOT NULL,
descripcion TEXT,
ficha_tecnica TEXT,
imagen_url VARCHAR(500),
peso_kg DECIMAL(8,3),
PRIMARY KEY (id),
KEY idx_sku (sku)
) ENGINE = SPIDER
COMMENT = 'server "srv_nodo05", table "v_productos_detalle"';
-- ================================================================
-- VIEW: productos
-- Reconstruye la relación completa mediante JOIN entre los dos
-- fragmentos verticales. Para el cliente en nodo06:
-- SELECT * FROM productos → indistinguible de una tabla local.
-- Internamente: Spider envía subconsulta a nodo04 y a nodo05,
-- el coordinador hace el JOIN y devuelve la fila completa.
32

-- ================================================================
CREATE OR REPLACE VIEW productos AS
SELECT
b.id,
b.sku,
b.nombre,
b.categoria,
b.precio,
b.stock,
d.descripcion,
d.ficha_tecnica,
d.imagen_url,
d.peso_kg,
b.fecha_creacion
FROM v_productos_basico b
JOIN v_productos_detalle d ON b.id = d.id;
-- ================================================================
-- VERIFICACIONES DE LOS FRAGMENTOS VERTICALES
-- ================================================================
SELECT 'v_productos_basico (Spider → nodo04)' AS fuente, COUNT(*)
AS productos
FROM v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider → nodo05)', COUNT(*)
FROM v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN distribuido)', COUNT(*)
FROM productos;
-- Resultado esperado: 10 / 10 / 10
-- Inspección del primer producto completamente reconstruido
SELECT id, sku, nombre, categoria, precio, stock,
LEFT(descripcion, 50) AS descripcion_preview,
LEFT(ficha_tecnica, 50) AS ficha_preview,
imagen_url,
peso_kg
FROM productos
WHERE id = 1;
EOF
33

E.15 Consultas de verificación distribuida desde nodo06 (VM — nodo06)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ================================================================
-- CONSULTA 1: Clientes de una sola región — poda Spider activa
-- WHERE region = 'norte' → Spider consulta solo frag_A (nodo04).
-- ================================================================
SELECT id,
CONCAT(nombre, ' ', apellido) AS cliente,
region,
ciudad
FROM clientes
WHERE region = 'norte'
ORDER BY id;
-- ================================================================
-- CONSULTA 2: Conteo de clientes por región (ambos shards)
-- Sin filtro → Spider consulta nodo04 Y nodo05 con UNION ALL.
-- ================================================================
SELECT region,
COUNT(*) AS clientes_por_region
FROM clientes
GROUP BY region
ORDER BY region;
-- ================================================================
-- CONSULTA 3: Productos con stock disponible (solo V_basico)
-- Solo activa nodo04; nodo05 no interviene.
-- ================================================================
SELECT sku, nombre, categoria, precio, stock
FROM v_productos_basico
WHERE stock > 0
ORDER BY precio DESC;
-- ================================================================
-- CONSULTA 4: Ficha completa de un producto (JOIN distribuido)
-- Activa nodo04 (v_productos_basico) Y nodo05 (v_productos_detalle).
-- ================================================================
SELECT id, sku, nombre, categoria, precio, stock,
descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos
WHERE id = 2;
-- ================================================================
-- CONSULTA 5: Pedidos con datos de cliente (JOIN en shards)
-- Spider usa poda en ambas tablas particionadas.
-- ================================================================
34

SELECT c.region,
CONCAT(c.nombre, ' ', c.apellido) AS cliente,
p.id AS pedido,
p.estado,
p.total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
ORDER BY c.region, p.id;
-- ================================================================
-- CONSULTA 6: HÍBRIDA — facturación por región con categorías
-- Cruza fragmentación HORIZONTAL (clientes/pedidos/detalle)
-- con fragmentación VERTICAL (v_productos_basico para categoría).
-- ================================================================
SELECT c.region,
COUNT(DISTINCT c.id) AS clientes_activos,
COUNT(DISTINCT p.id) AS num_pedidos,
GROUP_CONCAT(DISTINCT vb.categoria
ORDER BY vb.categoria) AS categorias,
ROUND(SUM(dp.subtotal), 2) AS facturacion_total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN v_productos_basico vb ON vb.id = dp.producto_id
GROUP BY c.region
ORDER BY facturacion_total DESC;
-- Resultado esperado: 4 filas con datos de facturación no nulos
-- ================================================================
-- CONSULTA 7: EXPLAIN — demostración de poda Spider
-- ================================================================
EXPLAIN SELECT id, nombre, ciudad
FROM clientes
WHERE region = 'norte';
EXPLAIN SELECT id, nombre, ciudad
FROM clientes;
-- ================================================================
-- RESUMEN GLOBAL — todas las métricas desde el coordinador
-- ================================================================
SELECT 'clientes (2 shards, PARTITION Spider)' AS metrica, COUNT(*) AS
valor FROM clientes
UNION ALL
SELECT 'pedidos (2 shards, PARTITION Spider)', COUNT(*)
FROM pedidos
UNION ALL
SELECT 'detalle_pedidos (VIEW UNION ALL)', COUNT(*)
FROM detalle_pedidos
35

UNION ALL
SELECT 'v_productos_basico (Spider → nodo04)', COUNT(*)
FROM v_productos_basico
UNION ALL
SELECT 'v_productos_detalle (Spider → nodo05)', COUNT(*)
FROM v_productos_detalle
UNION ALL
SELECT 'productos VIEW (JOIN distribuido)', COUNT(*)
FROM productos;
-- Resultado esperado:
-- clientes → 20
-- pedidos → 20
-- detalle_pedidos → ~36
-- v_productos_basico → 10
-- v_productos_detalle → 10
-- productos → 10
EOF
E.16 Apagar las VMs y tomar los snapshots fase14-completa (host)
Bash
# Desde la sesión SSH de nodo06
sudo poweroff
# Desde la sesión SSH de nodo04 (si sigue abierta)
sudo poweroff
# Desde la sesión SSH de nodo05 (si sigue abierta)
sudo poweroff
Confirmar:
PowerShell
VBoxManage list runningvms
# Salida esperada: vacía
Tomar los snapshots en los seis nodos:
36

PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase14-completa" `
--description "Sin cambios en Fase 14. Nodo de referencia. Snapshot de hito."
VBoxManage snapshot "bdd-nodo02" take "fase14-completa" `
--description "Sin cambios en Fase 14. Esclavo de replicacion. Snapshot
de hito."
VBoxManage snapshot "bdd-nodo03" take "fase14-completa" `
--description "Sin cambios en Fase 14. Nodo multi-maestro. Snapshot de hito."
VBoxManage snapshot "bdd-nodo04" take "fase14-completa" `
--description "SHARD-A: v_productos_basico creada y poblada (10 filas).
spider_user@192.168.56.106 con SELECT/INSERT/UPDATE/DELETE en lab_bdd.*."
VBoxManage snapshot "bdd-nodo05" take "fase14-completa" `
--description "SHARD-B: v_productos_detalle creada y poblada (10 filas).
spider_user@192.168.56.106 con SELECT/INSERT/UPDATE/DELETE en lab_bdd.*."
VBoxManage snapshot "bdd-nodo06" take "fase14-completa" `
--description "COORDINADOR: Spider ACTIVE, server_id=6, log_bin=OFF. CREATE
SERVER nodo04/nodo05. Spider tables: clientes, pedidos (PARTITION LIST
region), spider_detalle_nodo04/05, v_productos_basico, v_productos_detalle.
VIEWs: detalle_pedidos (UNION ALL), productos (JOIN). Consultas
distribuidas verificadas."
Confirmar:
PowerShell
VBoxManage snapshot "bdd-nodo04" list
VBoxManage snapshot "bdd-nodo05" list
VBoxManage snapshot "bdd-nodo06" list
nodo04 y nodo05 deben mostrar fase05-completa hasta fase14-completa . nodo06 muestra
únicamente fase14-completa (primer snapshot de esta VM).
F. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen todos los puntos siguientes:
 SELECT COUNT(*) FROM lab_bdd.v_productos_basico en nodo devuelve exactamente

37

 SELECT COUNT(*) FROM lab_bdd.v_productos_detalle  en nodo devuelve exactamente

 DESCRIBE lab_bdd.v_productos_basico  en nodo no muestra las columnas
| descripcion   |              |     |              |     |
| ------------- | ------------- | --- | ------------ | --- |
| ficha_tecnica |   imagen_url |     |  ni  peso_kg |    |
 DESCRIBE lab_bdd.v_productos_detalle  en nodo no muestra las columnas  nombre 
| categoria |   precio |   stock |  ni  fecha_creacion |    |
| --------- | --------- | -------- | ------------------- | --- |
 Las verificaciones de correctitud del paso E devuelven  OK  para completitud y disjunción
de columnas en ambos nodos
 ip addr show  en nodo muestra la dirección  192.168.56.106/24 
|  hostname                        |  en nodo devuelve  |     | bdd-nodo06               |    |
| ---------------------------------- | -------------------- | --- | ------------------------ | --- |
|  SHOW VARIABLES LIKE 'server_id' |                      |     |  en nodo devuelve    |     |
|  SHOW VARIABLES LIKE 'log_bin'   |                      |     |  en nodo devuelve OFF |     |
 SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME =
'SPIDER'
en nodo devuelve ACTIVE
 SHOW TABLES IN mysql LIKE 'spider%'  en nodo devuelve al menos  tablas de
sistema
 SELECT Server_name, Host FROM mysql.servers ORDER BY Server_name  en nodo
muestra
exactamente  filas  srv_nodo04  con IP  .104  y  srv_nodo05  con IP  .105 
 mysql -h 192.168.56.104 -u spider_user -p'Spider_2025!' -e "SELECT 1"  ejecutado
| desde nodo devuelve  |     |  sin errores |     |     |
| ---------------------- | --- | ------------- | --- | --- |
1
  ejecutado
mysql -h 192.168.56.105 -u spider_user -p'Spider_2025!' -e "SELECT 1"
| desde nodo devuelve  |     | 1  sin errores |     |     |
| ---------------------- | --- | --------------- | --- | --- |
 SELECT COUNT(*) FROM lab_bdd.clientes  en nodo devuelve 
 SELECT COUNT(*) FROM lab_bdd.pedidos  en nodo devuelve 
 SELECT COUNT(*) FROM lab_bdd.detalle_pedidos  en nodo devuelve el total correcto
 SELECT COUNT(*) FROM lab_bdd.v_productos_basico  en nodo devuelve  (desde
nodo)
 SELECT COUNT(*) FROM lab_bdd.v_productos_detalle  en nodo devuelve  (desde
nodo)
 SELECT COUNT(*) FROM lab_bdd.productos  (VIEW) en nodo devuelve  (JOIN
distribuido)
 La Consulta  (híbrida) de E devuelve exactamente  filas con valores de
facturación no nulos una por cada región del dominio
38

 EXPLAIN SELECT * FROM clientes WHERE region = 'norte'  en nodo muestra
únicamente
| frag_A  en la columna  | partitions |    |
| ---------------------- | ---------- | --- |
 EXPLAIN SELECT * FROM clientes  sin filtro en nodo muestra ambas particiones
| ( frag_A  y  frag_B ) |     |     |
| ---------------------- | --- | --- |
 SHOW TABLES IN lab_bdd  en nodo devuelve exactamente  clientes   pedidos 
spider_detalle_nodo04   spider_detalle_nodo05   v_productos_basico 
v_productos_detalle  y las VIEWs  detalle_pedidos  y  productos 
 Los snapshots  fase14-completa  existen en los seis nodos del laboratorio
39

G. Problemas comunes y soluciones
| Problema          | Causa probable | Solución         |     |
| ----------------- | -------------- | ---------------- | --- |
| INSTALL SONAME    | El archivo     | Ejecutar  sudo   |     |
| 'ha_spider'       |   ha_spider.so |   apt-get        |     |
| falla con  ERROR  | no está en la  | install -y       |     |
| 1126: Can't       | instalación    | mariadb-         |     |
| open shared       | actual de      | plugin-spider    |     |
|                   | MariaDB        | y reintentar el  |     |
library
INSTALL
'ha_spider'
SONAME 
verificar ruta
con  find
/usr/lib/mysql
/usr/lib/maria
db -name
"ha_spider*"
2>/dev/null
| SELECT ...     | Spider no           | Probar desde         |     |
| -------------- | ------------------- | -------------------- | --- |
| FROM clientes  |   alcanza el shard  | nodo:  mysql       |     |
| en nodo      | remoto             | bind- -h             |     |
| devuelve       | ERROR  address =    | 192.168.56.104       |     |
| 12502: Unable  | 127.0.0.1           |  en  -u spider_user  |     |
| to connect to  | nodo/          | -                    |     |
| foreign data   | firewall activo o  | p'Spider_2025!       |     |
| source         | credenciales        | ' -e "SELECT         |     |
incorrectas  si falla
1"
verificar
SHOW
VARIABLES LIKE
'bind_address
'  en nodo y
que el usuario
existe con
SELECT User,
Host FROM
mysql.user
WHERE
User='spider_u
ser'
| ERROR 1429:  | Las              | Verificar en  |     |
| ------------ | ---------------- | ------------- | --- |
|              | credenciales de  | nodo/:    |     |
Unable to
|     | CREATE SERVER |   SHOW GRANTS  |     |
| --- | ------------- | -------------- | --- |
connect to
40

| foreign data  | no coinciden               | FOR            |     |
| ------------- | -------------------------- | -------------- | --- |
| source        |  al crear  con el usuario  | 'spider_user'@ |     |
| tabla Spider  | real del nodo              | '192.168.56.10 |     |
|               | remoto                     | 6'  ejecutar  |     |
GRANT SELECT,
INSERT,
UPDATE, DELETE
ON lab_bdd.*
TO
'spider_user'@
'192.168.56.10
6'; FLUSH
|     |     | PRIVILEGES; |  si  |
| --- | --- | ----------- | ---- |
el usuario no
tiene los
privilegios
correctos
| La VIEW           | Los IDs en       | Verificar con   |     |
| ----------------- | ---------------- | --------------- | --- |
| productos         |   v_productos_ba | SELECT id FROM  |     |
| devuelve  filas  | sico  (nodo)   | lab_bdd.v_prod  |     |
| aunque los        | y en             | uctos_basico    |     |
fragmentos
|     | v_productos_de | ORDER BY id |     |
| --- | -------------- | ----------- | --- |
tienen  filas
talle   en nodo y
cada uno
|     | (nodo) no  | SELECT id FROM  |     |
| --- | ------------ | --------------- | --- |
|     | coinciden    | lab_bdd.v_prod  |     |
uctos_detalle
|     |     | ORDER BY id |     |
| --- | --- | ----------- | --- |
en nodo si
difieren
repoblar el
fragmento
incorrecto con
TRUNCATE
TABLE; INSERT
INTO ...
SELECT ...
FROM productos
ORDER BY id
| CREATE SERVER |   Ya existe un    | Ejecutar  DROP  |     |
| ------------- | ----------------- | --------------- | --- |
| falla con     | servidor con ese  |                 |     |
|               | ERROR             | SERVER IF       |     |
nombre de una
| 1409: Failed  |     | EXISTS  |     |
| ------------- | --- | ------- | --- |
ejecución previa
| to create  |     | srv_nodo04;  |     |
| ---------- | --- | ------------ | --- |
DROP SERVER IF
41

| default          |                      | EXISTS         |     |
| ---------------- | -------------------- | -------------- | --- |
| foreign          |                      | srv_nodo05;    |  y  |
| server           |                      | recrearlos     |     |
| La tabla Spider  | La definición        | Verificar con  |     |
| clientes         |  en  Spider incluye  | DESCRIBE       |     |
esa columna
| nodo          |                | lab_bdd.client |     |
| --------------- | -------------- | -------------- | --- |
| devuelve error  | pero la tabla  |                |     |
es  en nodo
| por columna  | remota fue  |     |     |
| ------------ | ----------- | --- | --- |
si la columna no
creada antes de
| ultima_modific |                | existe eliminarla  |     |
| -------------- | -------------- | ------------------- | --- |
|                | que existiera  | de la definición    |     |
acion
|     | (snapshot pre- | Spider  |     |
| --- | -------------- | -------- | --- |
ALTER
Fase )
TABLE clientes
DROP COLUMN
ultima_modific
acion;  en
nodo
| VBoxManage      | El nombre           | Ejecutar       |     |
| --------------- | ------------------- | -------------- | --- |
| clonevm         |  falla  exacto del  | VBoxManage     |     |
| con  Could not  | snapshot difiere    | snapshot "bdd- |     |
| find a          | (espacios          | nodo01" list   |     |
| snapshot named  | mayúsculas         | y copiar el    |     |
|                 | caracteres          | nombre exacto  |     |
'fase07-
especiales)
del snapshot
completa'
correspondiente
a la instalación
de MariaDB
| SSH a  .101      |   nodo sigue   | Verificar con  |     |
| ---------------- | ---------------- | -------------- | --- |
| conecta al nodo  | encendido con    | VBoxManage     |     |
| equivocado       | la misma IP que  | list           |     |
| durante la       | el clon          | runningvms     |     |
| configuración    |                  | que nodo     |     |
| de nodo        |                  | esté apagado   |     |
antes de
arrancar
nodo (paso
E)
| netplan apply    |   El archivo  | Usar el        |       |
| ---------------- | ------------- | -------------- | ----- |
| falla con error  | .yaml  tiene  | comando        | sed - |
| de sintaxis      | problemas de  | i              |       |
| YAML             | indentación   | 's/192\\.168\\ |       |
.56\\.101/192.
|     |     | 168.56.106/g' |     |
| --- | --- | ------------- | --- |
en lugar de
42

editar
manualmente
validar con
sudo netplan
try  antes de
aplicar YAML
requiere
espacios no
tabulaciones
| EXPLAIN  en      | Algunos clientes  | Usar la sintaxis  |     |
| ---------------- | ----------------- | ----------------- | --- |
| tabla Spider     | MariaDB no        | alternativa       |     |
| particionada no  | despliegan esta   | EXPLAIN           |     |
| muestra la       | columna           | PARTITIONS        |     |
automáticament
| columna  |     | SELECT ... |    |
| -------- | --- | ---------- | --- |
e para tablas
| partitions |     | también se  |     |
| ---------- | --- | ----------- | --- |
Spider
puede verificar
la poda
observando
SHOW STATUS
LIKE
'Handler_read%
 antes y
'
después de
consultas con y
sin filtro de
región
| La Consulta   | Alguna región    | Verificar que  |     |
| -------------- | ---------------- | -------------- | --- |
| (híbrida)      | no tiene líneas  |                |     |
spider_detalle
| devuelve menos  | de  |         |     |
| --------------- | --- | ------- | --- |
|                 |     | _nodo04 |  y  |
de  filas
|     | detalle_pedido | spider_detalle |     |
| --- | -------------- | -------------- | --- |
 con
|     | s   | _nodo05 |  tienen  |
| --- | --- | ------- | -------- |
coincidencia en
filas ( SELECT
|     | v_productos_ba | COUNT(*) FROM  |      |
| --- | -------------- | -------------- | ---- |
|     | sico           | spider_detalle |      |
|     |                | _nodo04        |  en  |
nodo)
|     |     | cambiar el  | JOIN  |
| --- | --- | ----------- | ----- |
v_productos_ba
|     |     | sico  por  | LEFT  |
| --- | --- | ---------- | ----- |
JOIN  si el
problema es
exclusión de
43

regiones sin
productos
comprados
| SHOW TABLES IN  | Las tablas de  | Localizar el  |       |
| --------------- | -------------- | ------------- | ----- |
|                 | sistema de     | script con    | find  |
mysql LIKE
|     | Spider no se  | /usr/share/mys |     |
| --- | ------------- | -------------- | --- |
'spider%'
| devuelve vacío  | crearon        | ql* -name      |     |
| --------------- | -------------- | -------------- | --- |
| tras            | automáticament |                |     |
| INSTALL         |                | "install_spide |     |
e
| SONAME |     | r.sql"  |     |
| ------ | --- | ------- | --- |
 y
2>/dev/null
ejecutar con
sudo mariadb <
ruta_del_scrip
t.sql
| El snapshot   | La VM no se     | Confirmar con    |       |
| ------------- | --------------- | ---------------- | ----- |
| fase14-       | apagó           | VBoxManage       |       |
| completa  de  | correctamente   | list             |       |
| nodo falla  | antes de tomar  | runningvms       |  si  |
| porque la VM  | el snapshot     | aparece apagar  |       |
| está en       |                 | con  VBoxManage  |       |
| ejecución     |                 | controlvm        |       |
"bdd-nodo06"
acpipowerbutto
n  y esperar 
segundos antes
de reintentar
H. Checklist de validación
spider_user@'192.168.56.106'  existe con  SELECT, INSERT, UPDATE, DELETE ON
lab_bdd.*
en nodo04 y en nodo05 (verificado con  ).
SHOW GRANTS
 existe en nodo04 con exactamente 10 filas y columnas
v_productos_basico
id, sku, nombre, categoria, precio, stock, fecha_creacion . Sin columnas TEXT de
detalle.
 existe en nodo05 con exactamente 10 filas y columnas
v_productos_detalle
id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg . Sin columnas
operacionales.
44

Las verificaciones de correctitud del paso E.5 devuelven  OK  (completitud y disjunción
de columnas) en ambos nodos.
bdd-nodo06  responde en  192.168.56.106  (verificado con  ip addr show ).
| hostname                        |  en nodo06 devuelve  | bdd-nodo06 | .                        |
| ------------------------------- | -------------------- | ---------- | ------------------------ |
| SHOW VARIABLES LIKE 'server_id' |                      |            |  devuelve 6 en nodo06.   |
| SHOW VARIABLES LIKE 'log_bin'   |                      |            |  devuelve OFF en nodo06. |
| SHOW VARIABLES LIKE 'read_only' |                      |            |  devuelve OFF en nodo06. |
SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME =
'SPIDER'
devuelve ACTIVE en nodo06.
SHOW TABLES IN mysql LIKE 'spider%'  devuelve al menos 6 tablas de sistema en
nodo06.
SELECT * FROM mysql.servers  muestra exactamente 2 filas en nodo06:
| srv_nodo04 |  (IP  .104 | ) y  srv_nodo05 |  (IP  .105 ). |
| ---------- | ---------- | --------------- | ------------- |
Conectividad verificada:  mysql -h 192.168.56.104 -u spider_user  desde nodo06
| retorna  1 | .   |     |     |
| ---------- | --- | --- | --- |
Conectividad verificada:  mysql -h 192.168.56.105 -u spider_user  desde nodo06
| retorna  1 | .   |     |     |
| ---------- | --- | --- | --- |
SELECT COUNT(*) FROM lab_bdd.clientes  en nodo06 devuelve 20.
| SELECT COUNT(*) FROM lab_bdd.pedidos |     |     |  en nodo06 devuelve 20. |
| ------------------------------------ | --- | --- | ----------------------- |
SELECT COUNT(*) FROM lab_bdd.detalle_pedidos  en nodo06 devuelve el total correcto.
SELECT COUNT(*) FROM lab_bdd.v_productos_basico  en nodo06 devuelve 10.
SELECT COUNT(*) FROM lab_bdd.v_productos_detalle  en nodo06 devuelve 10.
SELECT COUNT(*) FROM lab_bdd.productos  (VIEW) en nodo06 devuelve 10.
La Consulta 6 (híbrida, E.15) devuelve 4 filas con facturación no nula.
EXPLAIN SELECT * FROM clientes WHERE region = 'norte'  en nodo06 muestra solo
frag_A .
EXPLAIN SELECT * FROM clientes  sin filtro muestra  frag_A  y  frag_B  en nodo06.
SHOW TABLES IN lab_bdd  en nodo06 devuelve exactamente 6 tablas + 2 VIEWs.
Los snapshots  fase14-completa  existen en los 6 nodos del laboratorio.
Puedo explicar sin ver el documento por qué  detalle_pedidos  usa dos tablas Spider
simples + VIEW en lugar de una tabla Spider particionada por  .
region
Puedo describir el recorrido completo de la consulta
SELECT * FROM productos WHERE
  id = 5  desde nodo06: qué subconsultas genera Spider, a qué nodos las envía y cómo
combina los resultados.
45

Puedo distinguir la transparencia de fragmentación (ocultar la división de datos) de
la transparencia de ubicación (ocultar en qué nodo físico están los datos).
Preguntas teóricas para estudiantes
 La VIEW productos en nodo realiza un JOIN entre v_productos_basico (Spider →
nodo)
y v_productos_detalle (Spider → nodo) Analiza qué ocurre internamente en el
coordinador
cuando el cliente ejecuta SELECT nombre, descripcion FROM productos WHERE id = 3 :
¿Spider
puede empujar el predicado WHERE id = 3 hacia ambos nodos antes de traer los datos
(predicate pushdown) o primero trae todas las filas de cada fragmento y luego filtra
localmente? ¿Qué volumen de datos cruzaría la red en cada caso para una tabla de
un millón
de productos? Relaciona la respuesta con el concepto de eficiencia de JOIN distribuido
 La tabla Spider clientes en nodo tiene PRIMARY KEY (id, region)  mientras que la
tabla remota en nodo tiene PRIMARY KEY (id)  Explica por qué Spider permite esta
discrepancia de definición de clave primaria Luego analiza si un cliente ejecuta
INSERT INTO clientes (id, nombre, apellido, region, ...) VALUES (21, 'Ana',
'López',
'norte', ...) directamente en nodo ¿ese INSERT llega a nodo? ¿qué validaciones
realiza Spider antes de reenviar la operación al shard remoto? ¿qué error recibirá si
intenta insertar un cliente con region = 'centro' (valor no definido en las particiones)?
 detalle_pedidos en nodo se implementó con dos tablas Spider simples más una
VIEW UNION ALL  Un estudiante propone agregar la columna region directamente a
detalle_pedidos en nodo y nodo (desnormalización) para poder usar
PARTITION BY LIST COLUMNS (region) igual que clientes y pedidos  Evalúa esta
propuesta ¿qué DDL habría que ejecutar en los shards? ¿qué mecanismo garantizaría
que detalle_pedidos.region coincida siempre con pedidos.region sin FK de motor?
y ¿qué gana el sistema en términos de rendimiento de poda si se adopta esta solución?
 CREATE SERVER almacena la contraseña de spider_user en mysql.servers  visible para
cualquier usuario con acceso SELECT a esa tabla en nodo Describe el vector de ataque
concreto si un atacante obtiene acceso de solo lectura a mysql.servers  e identifica tres
medidas de mitigación distintas —sin cambiar la arquitectura Spider— que reducirían ese
riesgo Una de ellas debe involucrar los privilegios concedidos a spider_user en
nodo y nodo otra debe ser a nivel del sistema operativo de nodo
46

 Clasifica los seis nodos del laboratorio según el teorema CAP justificando cada
clasificación con argumentos técnicos concretos del diseño actual Por ejemplo ante una
partición de red entre nodo y nodo mientras una consulta a la VIEW productos está
en curso ¿el coordinador elige Consistencia (rechaza la consulta) o Disponibilidad
(devuelve datos parciales de nodo)? ¿Y el par nodo-nodo en replicación asíncrona
ante la caída de nodo antes de que un evento del binlog llegara a nodo?
Ejercicios prácticos
 Monitoreo del tráfico Spider entre coordinador y shards
En nodo ejecutar sudo tcpdump -i enp0s8 -n port 3306 -c 100 en segundo plano
mientras
se ejecutan desde nodo las siguientes tres consultas en secuencia
(a) SELECT precio FROM v_productos_basico WHERE id = 1 
(b) SELECT descripcion FROM v_productos_detalle WHERE id = 1 
© SELECT * FROM productos WHERE id = 1 (VIEW)
Repetir el experimento con el tcpdump en nodo Para cada consulta registrar en qué
nodo(s) aparece tráfico TCP Concluir ¿la consulta (a) activa solo nodo? ¿la consulta
(b) activa solo nodo? ¿la VIEW de © activa ambos nodos incluso cuando el WHERE
filtra una sola fila por id ? Documentar la salida del tcpdump con evidencia
 Inserción coordinada de un nuevo producto y observación del estado intermedio
Insertar manualmente el producto id = 11 en dos pasos separados
(a) Ejecutar INSERT INTO lab_bdd.v_productos_basico (id, sku, nombre, ...)
directamente
en nodo Luego consultar SELECT COUNT(*) FROM productos desde nodo y observar
qué devuelve la VIEW en estado intermedio (solo un fragmento insertado)
(b) Ejecutar INSERT INTO lab_bdd.v_productos_detalle (id, sku, descripcion, ...)
en nodo
Consultar nuevamente SELECT * FROM productos WHERE id = 11 desde nodo y
verificar que
ahora devuelve la fila completa
© Eliminar el producto de ambos fragmentos y confirmar que la VIEW vuelve a  filas
Discutir ¿qué problema de consistencia expone el estado intermedio? ¿Cómo lo resolvería
una transacción distribuida XA en un entorno de producción real?
 Script de auditoría de sincronía entre fragmentos verticales
Escribir un script Bash en nodo que conecte a nodo y a nodo con mysql -h IP
-u spider_user y compare los conjuntos de id presentes en v_productos_basico y
47

en v_productos_detalle  El script debe imprimir [OK] Fragmentos sincronizados:
N productos si los IDs coinciden o [FALLA] IDs solo en V_basico: X / solo en
V_detalle: Y si difieren Ejecutarlo en condiciones normales luego insertar
deliberadamente una fila solo en nodo para crear un desajuste confirmar que el
script lo detecta eliminar la fila y verificar que el script vuelve a reportar OK 
Reto adicional para alumnos avanzados
Investigar y diseñar una solución para escritura distribuida transparente desde nodo06
a través de la VIEW productos . La VIEW actual es de solo lectura porque MariaDB no sabe
cómo descomponer automáticamente un INSERT INTO productos (...) en dos inserciones
separadas hacia dos tablas Spider en dos nodos distintos.
Implementar una de las dos soluciones siguientes y documentar el resultado completo:
Opción A — Stored Procedure:
Crear CALL insertar_producto(sku, nombre, categoria, precio, stock, descripcion,
ficha_tecnica,
imagen_url, peso_kg) en nodo06 que: (1) inserta las columnas operacionales en nodo04 via
la tabla Spider v_productos_basico , captura el LAST_INSERT_ID() generado, y (2) inserta
las columnas de detalle en nodo05 via v_productos_detalle usando ese mismo ID.
Demostrar
la llamada, verificar que el nuevo producto aparece en la VIEW productos , y discutir qué
garantía de atomicidad ofrece este procedimiento ante la caída de nodo05 entre los pasos 1
y 2.
Opción B — Trigger sobre VIEW:
Investigar si MariaDB soporta triggers INSTEAD OF sobre VIEWs (disponibles en SQLite y
PostgreSQL, no en MySQL/MariaDB estándar). Si no es posible, demostrar ese límite con
el error que produce intentar crear el trigger, explicar técnicamente por qué el motor no
puede soportarlo sin cambios en la arquitectura, y proponer qué extensión de Spider o qué
configuración de replicación permitiría escrituras bidireccionales transparentes desde nodo06.
48

Criterios de evaluación para el profesor
| Criterio | Peso | Indicador de  |
| -------- | ---- | ------------- |
logro
| Fragmentos     | % | v_productos_ba |
| -------------- | --- | -------------- |
| verticales en  |     | sico  y        |
| nodo/nodo  |     | v_productos_de |
talle  existen
con las
columnas
correctas y 
filas las
verificaciones
de completitud
y disjunción
devuelven  
OK
el estudiante
relaciona las
columnas con el
criterio de
afinidad del
DDD (Fase )
| Configuración  | % | nodo tiene IP  |
| -------------- | --- | ---------------- |
| de nodo      |     | .106            |
| (MariaDB +     |     | server_id =      |
| Spider)        |     |                 |
6 log_bin =
 Spider
OFF
 tablas
ACTIVE

spider_*
presentes el
estudiante
puede mostrar
SHOW
VARIABLES  con
los valores
esperados y
explicar por qué
log_bin = OFF
en el
coordinador
  %
| CREATE SERVER   |     | mysql.servers    |
| --------------- | --- | ---------------- |
| y conectividad  |     | muestra los dos  |
| Spider          |     | servidores la   |
49

prueba de
conectividad
TCP desde
nodo pasa sin
error el
estudiante
puede explicar
la diferencia
entre usar
CREATE SERVER
vs credenciales
directas en el
COMMENT y las
implicaciones de
seguridad de
cada opción
Tablas Spider % clientes y
horizontales pedidos en
y poda nodo
devuelven 
filas EXPLAIN
confirma poda
con filtro de
región el
estudiante
justifica por qué
detalle_pedido
s requiere un
diseño diferente
y lo demuestra
con la
implementación
de dos tablas
Spider + VIEW
Fragmentos % v_productos_ba
verticales via sico y
Spider y VIEW v_productos_de
productos talle en
nodo
devuelven 
filas VIEW
productos
devuelve 
filas con todos
los atributos el
50

estudiante
puede describir
el JOIN
distribuido que
ocurre
internamente
en Spider
para resolver
esa VIEW
Consultas % Las  consultas
distribuidas y de E
transparencia producen
resultados
correctos la
Consulta 
(híbrida)
devuelve  filas
el estudiante
puede explicar
para cada
consulta cuáles
nodos activa
Spider cuándo
aplica poda y
cuándo realiza
UNION ALL
Preparación para la siguiente fase
La Fase 15: Fragmentación Híbrida requerirá:
• bdd-nodo06 completamente operativo con Spider (esta fase) todas las tablas Spider
y VIEWs funcionando conectividad verificada hacia nodo y nodo snapshots
fase14-completa en los seis nodos
• Comprensión clara de la diferencia de rendimiento entre acceso a un solo fragmento
( v_productos_basico  solo nodo) versus JOIN distribuido (VIEW productos  nodo
• nodo) establecida experimentalmente en las consultas de E
• El Documento de Diseño Distribuido ( C:\LabBDD\Documentacion\fase09-disenyo-
distribuido.md 
sección D Consulta Distribuida ) como referencia técnica esa consulta híbrida es
exactamente la Consulta  de esta fase ahora ejecutándose sobre la infraestructura real
51

En la Fase 15 se analizarán en profundidad las consultas que demuestran la fragmentación
híbrida como propiedad emergente del diseño actual: el cliente conectado a nodo06 ejecutará
SQL que accede simultáneamente a fragmentos horizontales (clientes y pedidos por
región entre
nodo04 y nodo05) y a fragmentos verticales (columnas de productos entre nodo04 y nodo05),
todo coordinado por Spider sin que el cliente perciba la distribución. Se introducirán además
estrategias de optimización: cuándo conviene filtrar antes del JOIN, cómo reducir el volumen
de datos transferidos entre coordinador y shards, y qué índices en los shards mejoran el
rendimiento de las subconsultas generadas por Spider.
52