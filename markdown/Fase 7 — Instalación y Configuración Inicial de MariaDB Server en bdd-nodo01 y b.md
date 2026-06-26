Fase 7 — Instalación y Configuración Inicial de
MariaDB Server en bdd-nodo01 y bdd-nodo02
Continuación directa de la Fase 6. Ambos nodos tienen Ubuntu Server 24.04 LTS con IP
estática configurada, OpenSSH activo y snapshot fase06-completa . En esta fase se instala
el motor de base de datos MariaDB Server en ambas VMs y se realiza su configuración
inicial (hardening básico y juego de caracteres). La instalación requiere acceso a internet,
que se habilita de forma controlada añadiendo un segundo adaptador de red en modo NAT
a cada VM; el adaptador Host-Only de la Fase 2 permanece intacto. La configuración
específica de replicación, binary log y usuarios de replicación no se realiza en esta fase;
corresponde a la Fase 10. Aquí solo se instala y verifica que el motor funciona
correctamente en cada nodo de forma independiente.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Justificar la elección de MariaDB frente a otras alternativas (MySQL PostgreSQL) para
este laboratorio de bases de datos distribuidas
 Añadir un segundo adaptador de red en modo NAT a una VM ya existente y en producción
sin reinstalar ni reconfigurar el adaptador Host-Only
 Actualizar la configuración de Netplan para que ambos adaptadores coexistan
correctamente comprendiendo cómo el kernel de Linux construye la tabla de rutas con
dos interfaces activas simultáneas
 Instalar mariadb-server desde los repositorios oficiales de Ubuntu  LTS
 Ejecutar mysql_secure_installation entendiendo el propósito de cada pregunta
interactiva y las implicaciones de cada respuesta para el laboratorio
 Comprender la estructura de archivos de configuración de MariaDB en Ubuntu
( mariadb.conf.d/ ) y el principio de sobrescritura por número de archivo para añadir
configuración propia sin modificar los archivos del paquete
 Configurar el juego de caracteres del servidor como utf8mb4 / utf8mb4_unicode_ci y
verificar que el motor los aplica
 Explicar qué es bind-address  cuál es su valor por defecto y por qué no se modifica en
esta fase
 Cerrar la fase con el snapshot fase07-completa en ambas VMs
1

B. Conceptos teóricos necesarios
1. MariaDB y su relación con MySQL.
MariaDB es una bifurcación (fork) directa de MySQL 5.5, creada en 2009 por los autores
originales de MySQL tras la adquisición de Sun Microsystems por Oracle. A nivel de protocolo
de red, formato de disco y lenguaje SQL, MariaDB mantiene compatibilidad con MySQL en la
gran mayoría de los casos: los clientes ( mariadb / mysql , DBeaver, Python/mysql-connector,
etc.) se conectan a ambos motores de la misma forma. Sin embargo, MariaDB ha divergido
intencionalmente en algunas áreas relevantes para este laboratorio:
• Incluye nativamente el motor de almacenamiento Spider que implementa fragmentación
distribuida directamente en el motor (se usará en las Fases –)
• Su implementación de GTID (Global Transaction Identifiers) y replicación paralela es más
madura y configurable que en MySQL para las topologías que se construirán en las Fases
–
• La licencia GPL v es más permisiva que la de MySQL Enterprise para uso educativo
• El paquete mariadb-server está incluido y mantenido oficialmente en los repositorios de
Ubuntu  LTS sin necesidad de fuentes externas
2. Versiones de MariaDB: LTS y versiones de desarrollo.
MariaDB tiene una política de versiones parecida a Ubuntu: existen ramas LTS con soporte
extendido y ramas de desarrollo con ciclos de vida más cortos. Ubuntu 24.04 LTS incluye
MariaDB 10.11 LTS, con soporte oficial hasta febrero de 2028. Existe también la rama 11.4 LTS
(disponible desde el repositorio oficial de la Fundación MariaDB), que es la más reciente al
momento de redactar esta guía. Este laboratorio usa la versión incluida en los repositorios de
Ubuntu 24.04 (10.11.x) por tres razones: no requiere agregar repositorios externos, la
documentación disponible en foros y tutoriales de replicación/fragmentación está ampliamente
probada en esta rama, y garantiza coherencia entre todos los nodos que se crearán en
fases futuras.
3. Por qué se necesita internet ahora, y cómo se incorpora de forma controlada.
Las fases anteriores intencionalmente dejaron los nodos sin acceso a internet: no era
necesario para instalar el sistema operativo (ya venía en la ISO) y el aislamiento de la red Host-
Only es una práctica correcta de laboratorio. Ahora, para instalar paquetes adicionales
mediante apt install mariadb-server , sí se necesita conectividad con los repositorios de
Ubuntu. La solución prevista desde la Fase 6 (sección B.3 de ese documento) es añadir un
segundo adaptador de red en modo NAT (Adaptador 2) a cada VM. VirtualBox implementa
NAT de forma interna para cada adaptador de ese tipo: la VM recibe una IP del DHCP
embebido de VirtualBox (rango 10.0.x.x ) y sale a internet a través del host, exactamente
igual que un dispositivo detrás de un router doméstico. El Adaptador 1 (Host-Only, enp0s3 )
permanece exactamente igual: misma dirección, mismo cable virtual. El Adaptador 2 nuevo
solo añade una ruta de salida hacia internet y no interfiere con la red interna del laboratorio.
2

4. Coexistencia de dos adaptadores y tabla de rutas.
Cuando enp0s3 tiene una IP estática sin gateway ( 192.168.56.101/24 ) y enp0s8 obtiene IP
y gateway por DHCP del motor NAT de VirtualBox, el kernel de Linux mantiene dos tipos de
entradas en la tabla de rutas:
• Una ruta directamente conectada 192.168.56.0/24 dev enp0s3 (todo el tráfico hacia la
red interna del laboratorio sale por enp0s3 )
• Una ruta por defecto 0.0.0.0/0 via 10.0.x.1 dev enp0s8 (todo lo demás —
repositorios actualizaciones cualquier destino externo — sale por enp0s8 )
No hay conflicto la ruta más específica siempre tiene preferencia en Linux El tráfico entre
nodos y hacia el host sigue por enp0s3  las descargas de paquetes van por enp0s8 
5. Estructura de configuración de MariaDB en Ubuntu.
En Ubuntu, MariaDB organiza su configuración bajo /etc/mysql/ :
• mariadb.cnf  archivo raíz que incluye mediante directivas !includedir los
subdirectorios conf.d/ y mariadb.conf.d/ 
• mariadb.conf.d/50-server.cnf  archivo principal del servidor contiene bind-address 
rutas de datos ( datadir ) configuración de logs tamaños de buffer etc Es el archivo que
instala el paquete mariadb-server y pertenece al sistema de paquetes
• mariadb.conf.d/99-*.cnf (convención de este laboratorio) archivos adicionales que se
cargan después de 50-server.cnf  Los archivos se procesan en orden alfanumérico de
modo que un archivo 99-* sobrescribe cualquier directiva que el 50-* haya declarado
Este mecanismo permite añadir configuración propia sin tocar los archivos del paquete lo
que facilita las actualizaciones y el diagnóstico
6. bind-address y por qué no se modifica todavía.
Por defecto, 50-server.cnf incluye bind-address = 127.0.0.1 , lo que significa que el
demonio de MariaDB solo acepta conexiones TCP desde el propio nodo (loopback). Esto es
correcto y seguro para esta fase: aún no hay ninguna razón para aceptar conexiones remotas.
En la Fase 10, cuando se configure la replicación física maestro-esclavo, se cambiará bind-
address a 0.0.0.0 (o a la IP Host-Only específica de cada nodo) para que el maestro pueda
recibir conexiones del esclavo. Modificar bind-address antes de ese momento abriría el
motor en la red interna sin que haya todavía usuarios ni privilegios remotos configurados.
7. Autenticación de root en MariaDB 10.11 en Ubuntu: unix_socket .
A diferencia de MySQL, donde el usuario root usa autenticación por contraseña desde la
instalación, MariaDB en Ubuntu configura root con el plugin de autenticación unix_socket
por defecto. Esto significa que el usuario Unix root (o cualquier usuario con sudo ) puede
acceder al motor con sudo mariadb sin necesidad de contraseña de MariaDB, porque el
kernel del sistema operativo ya verificó la identidad del proceso. Este mecanismo es más
seguro que una contraseña fija para acceso local, porque no existe ninguna contraseña que
3

pueda filtrarse. Sin embargo, para poder hacer pruebas de conexión con contraseña explícita
(útil en fases de replicación y con herramientas como DBeaver), en esta fase también se
establece una contraseña de respaldo para root .
8. mysql_secure_installation .
Este script interactivo, incluido con la instalación de MariaDB (en versiones más recientes
puede llamarse mariadb-secure-installation ), realiza cuatro acciones de seguridad sobre
una instalación recién hecha: ofrece gestionar la contraseña del usuario root de MariaDB,
elimina los usuarios anónimos creados por defecto, restringe el acceso remoto del usuario
root , y elimina la base de datos test . Ninguna de estas acciones afecta a la replicación
(que usará usuarios dedicados, no root ). Son tareas de higiene de instalación que en un
servidor real siempre se ejecutan antes de poner el motor en uso.
9. Juego de caracteres utf8mb4 vs. utf8 .
En MySQL/MariaDB, el juego de caracteres históricamente llamado utf8 es una
implementación incompleta de UTF-8 que soporta únicamente hasta 3 bytes por carácter,
excluyendo los emojis y muchos caracteres del plano suplementario de Unicode. El juego
utf8mb4 es la implementación completa de 4 bytes conforme al estándar. Dado que en las
fases de fragmentación y consultas distribuidas se trabajará con datos de texto heterogéneos,
configurar utf8mb4 desde el inicio evita tener que migrar esquemas y datos más adelante.
C. Procedimiento paso a paso
Paso 1 — Confirmar que ambas VMs están apagadas.
Añadir un adaptador de red a una VM requiere que esté detenida. Verificar el estado antes de
continuar (sección D.1).
Paso 2 — Añadir el Adaptador 2 en modo NAT a bdd-nodo01 y bdd-nodo02 desde el host.
Un solo comando por VM; VirtualBox registra el cambio de inmediato (sección D.2).
Paso 3 — Iniciar bdd-nodo01 en modo sin cabeza (headless) y conectarse por SSH.
A partir de esta fase, la forma de trabajo preferida es SSH desde el host; la consola gráfica de
VirtualBox se reserva para situaciones sin red disponible (sección D.3).
Paso 4 — Identificar el nombre del nuevo adaptador dentro de la VM.
El adaptador NAT aparecerá en el sistema operativo como una interfaz adicional (típicamente
enp0s8 en VirtualBox con chipset PIIX3). Confirmar el nombre exacto antes de editar Netplan.
Paso 5 — Actualizar el archivo de Netplan para incluir enp0s8 con DHCP.
Añadir la sección del nuevo adaptador al YAML existente, sin modificar la sección de enp0s3
(sección D.4).
4

Paso 6 — Aplicar la configuración y verificar conectividad a internet.
netplan apply , verificar la IP de NAT y probar el acceso real a los repositorios de Ubuntu
(sección D.5).
Paso 7 — Actualizar el índice de paquetes e instalar mariadb-server .
apt update seguido de apt install ; el paquete habilita e inicia el servicio automáticamente
al terminar (sección D.6).
Paso 8 — Ejecutar mysql_secure_installation .
Proceso interactivo; la tabla de la sección D.7 detalla cada pregunta y la respuesta
recomendada con su justificación.
Paso 9 — Crear el archivo de configuración de juego de caracteres.
Nuevo archivo 99-lab-charset.cnf en mariadb.conf.d/ ; no se edita 50-server.cnf
(sección D.8).
Paso 10 — Reiniciar el servicio para que tome los nuevos parámetros.
systemctl restart mariadb y verificación de estado (sección D.9).
Paso 11 — Verificar la instalación completa dentro del motor.
Conectar con sudo mariadb , confirmar versión, juego de caracteres y bases de datos
presentes (sección D.10).
Paso 12 — Repetir los Pasos 3 a 11 para bdd-nodo02 .
Exactamente el mismo procedimiento. El único valor que cambia en Netplan es la IP de
enp0s3 ( .102 ), que ya estaba configurada desde la Fase 6 y no se toca; la sección de
enp0s8 es idéntica. Todo lo demás de MariaDB (juego de caracteres, respuestas de
mysql_secure_installation ) es igual en ambos nodos.
Paso 13 — Apagar ambas VMs de forma ordenada y tomar el snapshot fase07-completa .
Sección D.11.
Paso 14 — Validar con el checklist de la sección G.
D. Comandos completos
Los comandos marcados (host) se ejecutan en PowerShell en Windows. Los marcados
(VM) se ejecutan en la sesión SSH de Ubuntu Server abierta desde el host, o en la consola
gráfica de VirtualBox si SSH no estuviera disponible por algún motivo.
5

D.1 Verificar que ambas VMs están apagadas (host)
PowerShell
VBoxManage list runningvms
La salida debe estar vacía. Si alguna VM aparece activa, apagarla antes de continuar:
PowerShell
VBoxManage controlvm "bdd-nodo01" acpipowerbutton
VBoxManage controlvm "bdd-nodo02" acpipowerbutton
Esperar unos segundos y volver a ejecutar list runningvms para confirmar que se
detuvieron.
D.2 Añadir el Adaptador 2 en modo NAT a ambas VMs (host)
PowerShell
VBoxManage modifyvm "bdd-nodo01" --nic2 nat
VBoxManage modifyvm "bdd-nodo02" --nic2 nat
Verificar que la configuración quedó registrada:
PowerShell
VBoxManage showvminfo "bdd-nodo01" | findstr "NIC 2"
VBoxManage showvminfo "bdd-nodo02" | findstr "NIC 2"
La salida debe mostrar NIC 2: con Attachment: NAT para cada VM.
D.3 Iniciar bdd-nodo01 y conectarse por SSH (host)
PowerShell
VBoxManage startvm "bdd-nodo01" --type headless
Esperar entre 15 y 30 segundos a que Ubuntu Server complete el arranque y, a continuación:
PowerShell
ssh bddadmin@192.168.56.101
6

--type headless inicia la VM sin abrir la ventana gráfica de VirtualBox, dado que toda la
administración es desde ahora por SSH. Si se necesita ver la consola gráfica (por ejemplo,
para depurar un problema de arranque), usar --type gui en su lugar.
D.4 Actualizar Netplan para incluir enp0s8 con DHCP (VM — bdd-nodo01 )
Primero, confirmar que el nuevo adaptador ya es visible en el sistema operativo y verificar su
nombre exacto:
Bash
ip a
Debe aparecer una interfaz adicional junto a lo y enp0s3 ; en VirtualBox con chipset PIIX3
suele llamarse enp0s8 . Si el nombre reportado es diferente (por ejemplo, ens8 o eth1 ), usar
ese nombre exacto en el paso siguiente.
Editar el archivo de Netplan:
Bash
sudo nano /etc/netplan/50-cloud-init.yaml
Contenido completo del archivo tras la edición (para bdd-nodo01 ):
YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: no
addresses:
- 192.168.56.101/24
enp0s8:
dhcp4: yes
Para bdd-nodo02 , la única diferencia es la IP de enp0s3 ; la sección de enp0s8 es idéntica:
7

YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: no
addresses:
- 192.168.56.102/24
enp0s8:
dhcp4: yes
Guardar con Ctrl+O , Enter y salir con Ctrl+X . Corregir los permisos del archivo:
Bash
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
D.5 Aplicar la configuración de red y verificar conectividad a internet (VM)
Bash
sudo netplan apply
Confirmar que enp0s8 obtuvo una IP del DHCP interno de VirtualBox (rango típico 10.0.2.x ):
Bash
ip a show enp0s8
Verificar que la tabla de rutas tiene tanto la ruta interna como la ruta por defecto:
Bash
ip route
Debe mostrar, al menos, estas dos líneas (los valores exactos de la ruta NAT variarán):
8

Text
default via 10.0.2.2 dev enp0s8 proto dhcp ...
192.168.56.0/24 dev enp0s3 proto kernel scope link src 192.168.56.101
Confirmar acceso real a los repositorios de Ubuntu:
Bash
ping -c 3 archive.ubuntu.com
Si responde sin pérdida de paquetes, la conectividad está lista. Si falla la resolución DNS,
revisar la sección F.
D.6 Actualizar el índice de paquetes e instalar MariaDB (VM)
Bash
sudo apt update
sudo apt install -y mariadb-server
La descarga e instalación trae varios paquetes (~30–60 MB según el estado de la caché) y
puede tardar algunos minutos. Al finalizar, apt habrá habilitado e iniciado el servicio mariadb
automáticamente.
Verificar que el servicio quedó activo inmediatamente después:
Bash
sudo systemctl status mariadb
Debe mostrar Active: active (running) .
D.7 Ejecutar mysql_secure_installation (VM)
Bash
sudo mysql_secure_installation
9

En algunas versiones de MariaDB o distribuciones el comando puede llamarse  mariadb-
. Si   no se encuentra, intentar con ese
secure-installation mysql_secure_installation
nombre alternativo.
El script es interactivo. La siguiente tabla detalla cada pregunta, la respuesta recomendada y
el motivo para este laboratorio:
| Pregunta del script | Respuesta  | Justificación |     |
| ------------------- | ---------- | ------------- | --- |
recomendada
Enter current password for root  Enter (vacío) La instalación fresca usa  unix_socket
| (enter for none): |     | contraseña de MariaDB establecida tod |     |
| ----------------- | --- | ------------------------------------- | --- |
n  ya está activo por defec
| Switch to unix_socket  |     | unix_socket |     |
| ---------------------- | --- | ----------- | --- |
responder   mantiene el estado actua
authentication [Y/n] n
cambios
Change the root password? [Y/n] Y → ingresar y  Establece una contraseña de respaldo
|     | confirmar una  | root  documentarla en  | C:\LabBDD\S |
| --- | -------------- | ----------------------- | ----------- |
|     | contraseña     | Notas\                  |             |
fuerte
Remove anonymous users? [Y/n] Y Elimina los usuarios sin nombre que pe
conexión sin credenciales
Disallow root login remotely?  Y El usuario  root  de MariaDB no debe a
| [Y/n] |     | conexiones desde otros nodos en la F |     |
| ----- | --- | ------------------------------------- | --- |
crearán usuarios de replicación dedica
Remove test database and access  Y Elimina la base de datos  test  de ejem
| to it? [Y/n] |     | innecesaria en un laboratorio serio |     |
| ------------ | --- | ----------------------------------- | --- |
Reload privilege tables now?  Y Aplica todos los cambios anteriores de
inmediato sin necesidad de reiniciar e
[Y/n]
La contraseña de  root  de MariaDB es independiente de la contraseña del usuario Unix
. Es la contraseña del superusuario administrativo del motor de base de datos,
bddadmin
no del sistema operativo. Usar la misma contraseña en ambos nodos simplifica la
administración del laboratorio; documentarla en la bitácora de la Fase 7 en
| C:\LabBDD\Snapshots-Notas\fase07-notas.txt | .   |     |     |
| ------------------------------------------ | --- | --- | --- |
D.8 Crear el archivo de configuración de juego de caracteres (VM)
Bash
sudo nano /etc/mysql/mariadb.conf.d/99-lab-charset.cnf
10

Contenido completo (idéntico en bdd-nodo01 y bdd-nodo02 ):
Text
# Configuración de juego de caracteres para el Laboratorio BDD
# Creado en la Fase 7. No modificar 50-server.cnf directamente.
# Este archivo se carga después de 50-server.cnf (orden alfanumérico)
# y sobrescribe las directivas de charset que declare.
[server]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
[client]
default-character-set = utf8mb4
Guardar con Ctrl+O , Enter y salir con Ctrl+X .
D.9 Reiniciar MariaDB para aplicar el nuevo juego de caracteres (VM)
Bash
sudo systemctl restart mariadb
sudo systemctl status mariadb
El servicio debe volver a estado active (running) en unos segundos.
D.10 Verificación completa dentro del motor (VM)
Conectar al motor como root local usando unix_socket (no se solicita contraseña en el
prompt del sistema operativo cuando se precede con sudo ):
Bash
sudo mariadb
Dentro del prompt MariaDB [(none)]> , ejecutar los siguientes comandos de verificación:
11

SQL
-- Versión instalada
SELECT VERSION();
-- Juego de caracteres del servidor
SHOW VARIABLES LIKE 'character_set_server';
-- Intercalación del servidor
SHOW VARIABLES LIKE 'collation_server';
-- Bases de datos presentes (solo las del sistema; no debe existir 'test')
SHOW DATABASES;
-- Confirmar bind-address (debe ser 127.0.0.1)
SHOW VARIABLES LIKE 'bind_address';
EXIT;
Resultados esperados (los valores de versión exactos variarán según la actualización
disponible en los repositorios):
12

Text
+------------------------------------------+
| VERSION() |
+------------------------------------------+
| 10.11.x-MariaDB-0ubuntu0.24.04.x |
+------------------------------------------+
+----------------------+---------+
| Variable_name | Value |
+----------------------+---------+
| character_set_server | utf8mb4 |
+----------------------+---------+
+--------------------+--------------------+
| Variable_name | Value |
+--------------------+--------------------+
| collation_server | utf8mb4_unicode_ci |
+--------------------+--------------------+
+--------------------+
| Database |
+--------------------+
| information_schema |
| mysql |
| performance_schema |
| sys |
+--------------------+
+--------------+-----------+
| Variable_name| Value |
+--------------+-----------+
| bind_address | 127.0.0.1 |
+--------------+-----------+
Verificar también que MariaDB está habilitado para arrancar automáticamente con el sistema:
Bash
sudo systemctl is-enabled mariadb
Debe responder enabled .
D.11 Apagar ambas VMs y tomar el snapshot fase07-completa (host)
Desde la sesión SSH en cada VM (o la consola gráfica):
13

Bash
sudo poweroff
Confirmar que ambas VMs están detenidas desde el host:
PowerShell
VBoxManage list runningvms
La salida debe estar vacía. Tomar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase07-completa" `
--description "MariaDB 10.11 instalado; utf8mb4 configurado;
mysql_secure_installation ejecutado; Adaptador NAT activo en enp0s8"
VBoxManage snapshot "bdd-nodo02" take "fase07-completa" `
--description "MariaDB 10.11 instalado; utf8mb4 configurado;
mysql_secure_installation ejecutado; Adaptador NAT activo en enp0s8"
Confirmar la lista de snapshots de ambas VMs:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
Cada VM debe mostrar dos snapshots: fase05-completa , fase06-completa y fase07-
completa .
E. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen todos los puntos siguientes en
ambos nodos:
 VBoxManage showvminfo "bdd-nodo01" | findstr NIC muestra el Adaptador  como
hostonly y el Adaptador  como nat  lo mismo para bdd-nodo02 
14

 ip a dentro de cada VM muestra enp0s3 con su IP estática de la Fase 
( 192.168.56.101 / .102 ) y enp0s8 con una IP del rango NAT de VirtualBox ( 10.0.2.x )
ambas en estado UP 
 ip route dentro de cada VM muestra una ruta default apuntando a enp0s8 y la ruta
directa 192.168.56.0/24 por enp0s3 
 ping -c 3 archive.ubuntu.com desde cada VM responde sin pérdida de paquetes
 La conectividad Host-Only de la Fase  sigue intacta ping 192.168.56.101 y ping
192.168.56.102 desde PowerShell en el host responden correctamente el adaptador
NAT no la interrumpió
 sudo systemctl status mariadb muestra Active: active (running) en ambos nodos
 sudo systemctl is-enabled mariadb responde enabled en ambos nodos
 SELECT VERSION() dentro de sudo mariadb muestra una versión 10.11.x-MariaDB 
 SHOW VARIABLES LIKE 'character_set_server' devuelve utf8mb4 
 SHOW VARIABLES LIKE 'collation_server' devuelve utf8mb4_unicode_ci 
 SHOW VARIABLES LIKE 'bind_address' devuelve 127.0.0.1 (no se ha modificado)
 SHOW DATABASES muestra las cuatro bases de datos del sistema y no existe la base de
datos test 
 Ambos snapshots fase07-completa existen y están asociados al estado apagado de cada
VM
 La contraseña de root de MariaDB está documentada en C:\LabBDD\Snapshots-
Notas\fase07-notas.txt 
15

F. Problemas comunes y soluciones
| Problema       | Causa probable           | Solución         |     |
| -------------- | ------------------------ | ---------------- | --- |
| VBoxManage     | La VM estaba             | Apagar la VM     |     |
| modifyvm ... - | encendida al             | con  VBoxManage  |     |
| -nic2 nat      |  falla  intentar añadir  | controlvm        |     |
| con “VM is     | el adaptador             | "bdd-nodo01"     |     |
| currently      |                          | acpipowerbutto   |     |
| running”       |                          | n  (o  sudo      |     |
|                |                          | poweroff         |     |
desde dentro)
esperar a que se
detenga
completamente
y repetir el
comando
| enp0s8          |  no  VirtualBox  | Ejecutar  ip a  |     |
| --------------- | ---------------- | --------------- | --- |
| aparece en      | ip  asignó un    | completo para   |     |
|  tras arrancar  | nombre de        | identificar la  |     |
a
| la VM | interfaz distinto  | interfaz nueva    |     |
| ----- | ------------------ | ----------------- | --- |
|       | al esperado o la  | (es la que no es  |     |
|       | VM arrancó         | lo  ni  enp0s3    | )  |
antes de que
usar ese nombre
VirtualBox
exacto en el
registrara el
YAML de
|     | cambio de  | Netplan |     |
| --- | ---------- | ------- | --- |
adaptador
|     |   El nombre de la  | Corregir el  |     |
| --- | ------------------ | ------------ | --- |
enp0s8
| aparece en  | interfaz en el  | nombre en  |     |
| ----------- | --------------- | ---------- | --- |
ip
archivo YAML no
| a  sin dirección  |     | /etc/netplan/5 |     |
| ----------------- | --- | -------------- | --- |
coincide
| IP tras  | netplan           | 0-cloud-          |        |
| -------- | ----------------- | ----------------- | ------ |
|          | exactamente       |                   |  para  |
| apply    |                   | init.yaml         |        |
|          | con el del kernel | que sea idéntico  |        |
al que muestra
ip a  (sensible
a mayúsculas y
números) y
volver a ejecutar
sudo netplan
apply
| ping  | La interfaz NAT  | Verificar con  |     |
| ----- | ---------------- | -------------- | --- |
no obtuvo
| archive.ubuntu |     | resolvectl  |     |
| -------------- | --- | ----------- | --- |
configuración
| .com  falla con  |     | status  si  |     |
| ---------------- | --- | ----------- | --- |
DNS del DHCP
| “Name or  |               | existe un     |     |
| --------- | ------------- | ------------- | --- |
|           | de VirtualBox | servidor DNS  |     |
service not
asignado a
known”
16

|     |     | enp0s8 |  si no  |
| --- | --- | ------ | --------- |
forzar la
renovación
|     |     | DHCP con  | sudo  |
| --- | --- | --------- | ----- |
dhclient
|     |     | enp0s8 |  y  |
| --- | --- | ------ | --- |
reintentar
|                | La ruta por    | Ejecutar      |        |
| -------------- | -------------- | ------------- | ------ |
| ping           |                |               | ip     |
|                | defecto no se  |               |  para  |
| archive.ubuntu |                | route         |        |
|  falla con     | estableció     | confirmar si  |        |
.com
| “Network is  | porque  enp0s8     |   existe la ruta  |          |
| ------------ | ------------------ | ----------------- | -------- |
| unreachable” | no recibió IP del  |                   |  si no  |
default
|     | DHCP | existe ejecutar  |     |
| --- | ---- | ----------------- | --- |
sudo dhclient
 y
enp0s8
verificar de
nuevo
| sudo apt       | El reloj del   | Dentro de la VM:  |     |
| -------------- | -------------- | ----------------- | --- |
| update  falla  | sistema de la  | sudo              |     |
VM está
| con errores de  |     | timedatectl  |     |
| --------------- | --- | ------------ | --- |
desincronizado
| certificado SSL  |     | set-ntp true |     |
| ---------------- | --- | ------------ | --- |
(diferencia de
| o de conexión |     | y esperar unos  |     |
| ------------- | --- | --------------- | --- |
más de algunos
segundos luego
minutos invalida
|     |     | reintentar  | apt  |
| --- | --- | ----------- | ---- |
certificados
update
TLS)
| apt install  | El índice de     | Ejecutar primero  |       |
| ------------ | ---------------- | ----------------- | ----- |
| mariadb-     | paquetes no se   | sudo apt          |       |
|  falla       | actualizó antes  | update            |  si  |
server
| con “E: Unable  | de instalar o la  | persiste         |       |
| --------------- | ------------------ | ----------------- | ----- |
| to locate       | URL de los         | verificar con     |       |
| package”        | repositorios en    | cat               |       |
|                 | sources.list       |   /etc/apt/sourc  |       |
|                 | no es correcta     | es.list           |  que  |
|                 | para Ubuntu        | los repositorios  |       |

apunten a
|     |     | noble |  (nombre  |
| --- | --- | ----- | --------- |
en clave de
Ubuntu )
| Tras la       | Conflicto de   | Revisar el log de  |     |
| ------------- | -------------- | ------------------ | --- |
| instalación  | puertos (el    | MariaDB con        |     |
| systemctl     | puerto     | sudo               |     |
| status        | estaba en uso  | journalctl -u      |     |
| mariadb       | por otro       | mariadb --no-      |     |
| muestra       | proceso) o     |                    |     |
pager -n 50
| failed  o  | problema de  | para identificar  |     |
| ---------- | ------------ | ----------------- | --- |
| inactive   |              | el error exacto  |     |
17

permisos en el lo más habitual
directorio de es un problema
datos de permisos que
se resuelve con
sudo
mysql_install_
db --
user=mysql
mysql_secure_i El servicio Ejecutar sudo
nstallation MariaDB no está systemctl
devuelve “Can’t activo start mariadb
connect to local antes de lanzar
MySQL server el script
through socket”
SHOW VARIABLES El archivo 99- Verificar la ruta
LIKE lab- exacta
'character_set charset.cnf ( /etc/mysql/ma
_server' tiene un error de riadb.conf.d/9
devuelve sintaxis está en 9-lab-
latin1 o utf8 la ruta charset.cnf )
en lugar de incorrecta o el revisar la
utf8mb4 servicio no se sintaxis (sección
reinició tras [server]
crearlo presente sin
espacios extra
alrededor del
= ) y ejecutar
sudo systemctl
restart
mariadb
Al reiniciar la El DHCP de NAT Esto no afecta a
VM la interfaz de VirtualBox a las funciones
enp0s8 pierde veces tarda en del laboratorio
la IP y no hay responder en el (los snapshots y
internet arranque las fases
posteriores solo
requieren la red
Host-Only) si se
necesita
internet en un
momento
concreto
ejecutar sudo
dhclient
enp0s8 dentro
de la VM
18

| La conectividad  | Conflicto de        | Verificar con  | ip  |     |
| ---------------- | ------------------- | -------------- | --- | --- |
| Host-Only        | rutas la ruta por  | route  que la  |     |     |
| ( ) dejó         | defecto de NAT      |                |     |     |
| enp0s3           |                     | ruta           |     |     |
puede interferir
| de funcionar  |                 | 192.168.56.0/2 |     |     |
| ------------- | --------------- | -------------- | --- | --- |
| tras añadir   | con el tráfico  |                |     |     |
|               |                 | 4 dev enp0s3   |     |     |
| enp0s8        | Host-Only en    |                |     |     |
sigue presente
casos raros
si no aparece
reactivar la
interfaz con
sudo ip link

set enp0s3 up
y
sudo netplan
apply
G. Checklist de validación
Ambas VMs estaban apagadas antes de añadir el Adaptador 2.
Añadí el Adaptador 2 en modo NAT a  bdd-nodo01  con  VBoxManage modifyvm "bdd-
.
nodo01" --nic2 nat
Añadí el Adaptador 2 en modo NAT a  bdd-nodo02  con  VBoxManage modifyvm "bdd-
nodo02" --nic2 nat .
Actualicé  /etc/netplan/50-cloud-init.yaml  en  bdd-nodo01  añadiendo  enp0s8:
| dhcp4: yes | , sin modificar la sección de  | enp0s3 | .   |     |
| ---------- | ------------------------------ | ------ | --- | --- |
netplan apply  se ejecutó sin errores en  bdd-nodo01  y  enp0s8  obtuvo una IP del rango
NAT de VirtualBox.
ping archive.ubuntu.com  respondió desde  bdd-nodo01 , confirmando acceso a internet.
sudo apt update && sudo apt install -y mariadb-server  completó sin errores en
| bdd-nodo01 | .   |     |     |     |
| ---------- | --- | --- | --- | --- |
Ejecuté  mysql_secure_installation  en  bdd-nodo01  respondiendo correctamente cada
pregunta, y documenté la contraseña de  root  de MariaDB en la bitácora del laboratorio.
Creé  /etc/mysql/mariadb.conf.d/99-lab-charset.cnf  con las directivas  utf8mb4  en
| bdd-nodo01 | .   |     |     |     |
| ---------- | --- | --- | --- | --- |
Reinicié el servicio  mariadb  en  bdd-nodo01  y verifiqué que  character_set_server =
| utf8mb4 |  está activo dentro del motor. |                                                      |     |     |
| ------- | ------------------------------ | ---------------------------------------------------- | --- | --- |
|         |  en                            |  muestra las cuatro bases de datos del sistema y no  |     |     |
SHOW DATABASES bdd-nodo01
| existe la base de datos  | test . |     |     |     |
| ------------------------ | ------ | --- | --- | --- |
SHOW VARIABLES LIKE 'bind_address'  en  bdd-nodo01  devuelve  127.0.0.1  (sin
modificar).
sudo systemctl is-enabled mariadb  en  bdd-nodo01  devuelve  enabled .
| Repetí y verifiqué todos los puntos anteriores en  |     |     | bdd-nodo02 | .   |
| -------------------------------------------------- | --- | --- | ---------- | --- |
19

La conectividad Host-Only sigue funcionando: ping 192.168.56.101 y ping
192.168.56.102 responden desde el host Windows.
Apagué ambas VMs de forma ordenada y tomé el snapshot fase07-completa en cada
una.
Puedo explicar qué es bind-address , cuál es su valor actual y por qué no se modificó en
esta fase.
Puedo explicar la diferencia entre la contraseña del usuario Unix bddadmin y la
contraseña del usuario root de MariaDB.
Preguntas teóricas para estudiantes
 ¿Por qué se eligió MariaDB y no MySQL o PostgreSQL para este laboratorio? Menciona al
menos dos características específicas de MariaDB que serán relevantes en fases
posteriores del laboratorio
 ¿Qué ocurre en la tabla de rutas del kernel de Linux cuando una misma VM tiene dos
adaptadores de red activos simultáneamente uno con IP estática y sin gateway y otro con
DHCP que sí proporciona gateway? ¿Qué tipo de tráfico seguiría cada ruta?
 Explica el mecanismo de unix_socket authentication en MariaDB ¿Por qué es
considerado más seguro que la autenticación por contraseña para el acceso local de
root ? ¿Cuándo no sería suficiente esta autenticación?
 ¿Qué diferencia existe entre el juego de caracteres utf8 y utf8mb4 en MariaDB y por
qué esta diferencia importa para bases de datos que almacenarán texto de usuarios
finales?
 ¿Por qué en esta fase se crea un archivo 99-lab-charset.cnf en lugar de editar
directamente 50-server.cnf ? ¿Qué problema podría causar editar 50-server.cnf
directamente si en el futuro se actualiza el paquete mariadb-server ?
Preparación para la siguiente fase
La Fase 8 requerirá:
• MariaDB  instalado configurado con utf8mb4 y accesible en ambos nodos (esta
fase)
• Snapshot fase07-completa tomado en bdd-nodo01 y bdd-nodo02 
• Acceso SSH funcional desde el host hacia ambos nodos (Fase )
• bind-address = 127.0.0.1 en su valor por defecto (no se ha modificado todavía)
20

A partir de la Fase 8, toda la interacción con los nodos se realizará exclusivamente por SSH
desde el host; no será necesario abrir la ventana gráfica de VirtualBox para las tareas
normales del laboratorio.
21