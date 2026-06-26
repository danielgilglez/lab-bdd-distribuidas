Fase 5 — Instalación de Ubuntu Server
24.04 LTS en bdd-nodo01 y bdd-nodo02
Continuación directa de las Fases 3 (creación de las VMs vacías) y 4 (descarga y
verificación de la ISO). En esta fase se instala por primera vez un sistema operativo real
dentro de las dos máquinas virtuales ya existentes. No se configura todavía la IP estática
(eso es la Fase 6); aquí solo se deja Ubuntu Server funcionando y accesible desde la
consola gráfica de VirtualBox.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Montar una imagen ISO en la unidad óptica virtual de una VM y ajustar el orden de
arranque para instalar un sistema operativo desde ella
 Completar la instalación de Ubuntu Server  LTS usando el instalador Subiquity
tomando decisiones informadas en cada pantalla (almacenamiento perfil SSH snaps)
 Explicar por qué se instala el paquete OpenSSH Server durante la instalación en lugar de
agregarlo después
 Entender por qué la pantalla de red del instalador mostrará la interfaz sin dirección IP y
por qué eso es el comportamiento esperado dado lo configurado en la Fase 
 Repetir el proceso de forma idéntica en dos nodos distintos garantizando consistencia
(mismo usuario administrador mismas decisiones de particionado) entre ambos
 Retirar correctamente el medio de instalación tras el primer reinicio evitando que la VM
vuelva a arrancar el instalador en lugar del sistema ya instalado
 Cerrar la fase con un snapshot por VM dejando un punto de restauración limpio antes de
tocar la red (Fase )
B. Conceptos teóricos necesarios
1. El instalador Subiquity. Desde Ubuntu 20.04, el instalador de Ubuntu Server usa Subiquity,
una interfaz de texto (TUI) navegable con teclado, mucho más ligera que el antiguo instalador
gráfico de Ubuntu Desktop. Es el mismo instalador tanto si se usa el modo gráfico de
VirtualBox como si se accede por consola serie; en este laboratorio se usará dentro de la
ventana de la VM en modo gráfico, simplemente para poder ver el proceso con claridad.
1

2. Orden de arranque y medio de instalación. Una VM recién creada (Fase 3) tiene un disco
vacío y una unidad óptica vacía: no hay nada que arrancar. Al montar la ISO de Ubuntu en la
unidad óptica y arrancar la VM, el firmware intenta los dispositivos en el orden configurado
( boot1 , boot2 , …); si la unidad óptica tiene prioridad y contiene un medio arrancable, el
instalador toma el control antes que el disco duro vacío.
3. Por qué instalar OpenSSH Server desde el instalador. Todo este laboratorio se
administrará de forma remota, por SSH, desde el host Windows (Fase 6 en adelante: scripts,
DBeaver, replicación). Subiquity ofrece una casilla explícita “Install OpenSSH server” durante
la instalación; marcarla evita tener que volver a entrar por la consola gráfica de VirtualBox
únicamente para instalar el paquete a mano. Es, además, la práctica estándar al aprovisionar
servidores reales sin entorno gráfico.
4. Por qué la pantalla de red mostrará “sin dirección”. En la Fase 2 se desactivó
deliberadamente el servidor DHCP del adaptador Host-Only, porque el laboratorio depende de
IPs fijas. Como consecuencia, cuando Subiquity llegue a la pantalla de configuración de red, la
interfaz enp0s3 (o el nombre que asigne el kernel) aparecerá sin dirección IPv4 asignada.
Esto es exactamente lo esperado en esta fase: no hay que configurar nada manualmente aquí,
simplemente continuar. La IP estática se asignará dentro del sistema operativo ya instalado, en
la Fase 6.
5. Consecuencia práctica: no hay acceso a internet durante la instalación. Como las VMs
solo tienen un adaptador Host-Only (sin NAT) y sin DHCP, no existe ruta de salida a internet en
este punto. Subiquity detectará esto y, según la versión, omitirá automáticamente la selección
de mirror/proxy y la instalación de actualizaciones y snaps destacados, o mostrará una
advertencia de “no se pudo verificar el mirror” que se puede ignorar y continuar. Esto es
normal y no es un error. Si una fase posterior requiere acceso a internet dentro de las VMs
(por ejemplo, para instalar el paquete de MariaDB), se resolverá en esa fase; no es necesario
adelantarlo aquí.
6. Particionado guiado y LVM. Subiquity ofrece “Use an entire disk” (particionado guiado)
como opción por defecto, con la casilla “Set up this disk as an LVM group” generalmente
marcada. Usar LVM agrega una capa de volúmenes lógicos que facilita redimensionar
particiones más adelante sin reparticionar desde cero; para discos de 20 GB dedicados a un
solo nodo no es estrictamente indispensable, pero se deja el valor por defecto (LVM activado)
por ser la práctica recomendada y no añade complejidad real en esta fase.
7. Snaps destacados (“Featured Server Snaps”). Subiquity ofrece instalar paquetes
adicionales empaquetados como snap (Docker, Nextcloud, etc.) al final del proceso. Ninguno
es necesario para este laboratorio (no se usa Docker, según el alcance definido en la Fase 0) y,
sin red disponible, tampoco podrían descargarse. Se dejan todos sin marcar.
2

8. Consistencia entre nodos. Para que los scripts y procedimientos de fases posteriores
(replicación, fragmentación) funcionen igual en todos los nodos, ambas VMs deben instalarse
con el mismo usuario administrador, el mismo esquema de particionado y la misma versión de
Ubuntu. Solo debe cambiar el nombre de host ( bdd-nodo01 vs. bdd-nodo02 ).
C. Procedimiento paso a paso
Paso 1 — Confirmar que las Fases 3 y 4 están completas.
Deben existir bdd-nodo01 y bdd-nodo02 (apagadas, sin sistema operativo) y el archivo
ubuntu-24.04.4-live-server-amd64.iso verificado en C:\LabBDD\ISOs .
Paso 2 — Montar la ISO en la unidad óptica de bdd-nodo01 .
La VM debe estar apagada. Ver comando en sección D.1.
Paso 3 — Ajustar el orden de arranque para que la unidad óptica tenga prioridad.
Ver comando en sección D.2. (En la práctica, como el disco duro está vacío, casi cualquier
orden funcionaría, pero fijarlo explícitamente evita ambigüedad).
Paso 4 — Iniciar bdd-nodo01 en modo gráfico.
Ver comando en sección D.3. Se abrirá una ventana de VirtualBox mostrando el arranque
del instalador.
Paso 5 — Navegar el instalador Subiquity.
En orden, las pantallas relevantes y la decisión recomendada para este laboratorio:
Untitled
Paso 6 — Retirar el medio de instalación.
Al reiniciar, Subiquity normalmente expulsa la ISO automáticamente y muestra el mensaje
“Please remove the installation medium, then press ENTER”. Si la VM vuelve a arrancar el
instalador en lugar del sistema instalado, apagarla y ejecutar manualmente el comando de la
sección D.4 para desmontar la ISO, luego volver a iniciarla.
Paso 7 — Primer inicio de sesión y verificación básica.
Una vez que aparezca el prompt de login ( bdd-nodo01 login: ), iniciar sesión con el usuario y
contraseña definidos en el Paso 5. Ejecutar los comandos de verificación de la sección D.5
dentro de la VM.
Paso 8 — Repetir los Pasos 2 a 7 para bdd-nodo02 .
Mismo procedimiento exacto, cambiando únicamente el nombre del servidor a bdd-nodo02 en
la pantalla de perfil. Usar el mismo nombre de usuario ( bddadmin ) por consistencia.
3

Paso 9 — Apagar ambas VMs de forma ordenada.
Dentro de cada VM, no desde el botón de cerrar la ventana de VirtualBox (ver comando D.6).
Paso 10 — Tomar el snapshot de cierre de fase.
Un snapshot por VM, nombrado fase05-completa (ver sección D.7), antes de tocar la
configuración de red en la Fase 6.
Paso 11 — Validar con el checklist de la sección G.
D. Comandos completos
Comandos en PowerShell sobre el host Windows, salvo donde se indique explícitamente
“dentro de la VM”.
D.1 Montar la ISO en bdd-nodo01 (VM apagada)
PowerShell
VBoxManage storageattach "bdd-nodo01" --storagectl "SATA Controller" --port 1
--device 0 --type dvddrive --medium "C:\LabBDD\ISOs\ubuntu-24.04.4-live-
server-amd64.iso"
D.2 Fijar el orden de arranque (DVD primero, disco después)
PowerShell
VBoxManage modifyvm "bdd-nodo01" --boot1 dvd --boot2 disk --boot3 none --
boot4 none
D.3 Iniciar la VM en modo gráfico
PowerShell
VBoxManage startvm "bdd-nodo01" --type gui
A partir de aquí la interacción es dentro de la ventana de la VM (instalador Subiquity),
según el Paso 5 de la sección C. No hay más comandos de PowerShell hasta que termine
la instalación.
4

D.4 Desmontar la ISO manualmente (si el instalador no la expulsa solo)
PowerShell
VBoxManage storageattach "bdd-nodo01" --storagectl "SATA Controller" --port 1
--device 0 --type dvddrive --medium emptydrive
D.5 Verificación básica dentro de la VM (tras el primer login)
Bash
hostnamectl
Debe mostrar Static hostname: bdd-nodo01 .
Bash
lsb_release -a
Debe mostrar Ubuntu 24.04.x LTS (Noble Numbat) .
Bash
ip a
La interfaz enp0s3 debe aparecer sin dirección IPv4 (esperado; se asigna en Fase 6).
Bash
systemctl status ssh
Debe mostrar active (running) , confirmando que OpenSSH Server quedó instalado y
activo.
Bash
free -h
df -h /
5

Para confirmar que la RAM (≈1.5 GB) y el disco (≈20 GB, con poco uso real) coinciden con lo
planeado en la Fase 0.
D.6 Apagar la VM de forma ordenada (dentro de la VM)
Bash
sudo poweroff
Alternativa desde el host, si la VM quedó sin responder (no usar como método habitual):
PowerShell
VBoxManage controlvm "bdd-nodo01" acpipowerbutton
D.7 Repetir D.1 a D.6 para bdd-nodo02
Mismos comandos, sustituyendo bdd-nodo01 por bdd-nodo02 en cada uno.
D.8 Tomar el snapshot de cierre de fase (ambas VMs apagadas)
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase05-completa" --description "Ubuntu
Server 24.04 LTS instalado, OpenSSH activo, sin IP estatica todavia"
VBoxManage snapshot "bdd-nodo02" take "fase05-completa" --description "Ubuntu
Server 24.04 LTS instalado, OpenSSH activo, sin IP estatica todavia"
D.9 Confirmar los snapshots creados
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
E. Verificación de funcionamiento
 bdd-nodo01 y bdd-nodo02 arrancan y muestran el prompt de login de Ubuntu Server (no
el instalador) tras reiniciar
6

 hostnamectl dentro de cada VM reporta el nombre de host correcto ( bdd-nodo01 / bdd-
nodo02 respectivamente)
 lsb_release -a confirma Ubuntu x LTS en ambos nodos
 systemctl status ssh reporta el servicio activo en ambos nodos (aunque todavía no se
pueda conectar por SSH desde el host porque falta la IP estática de la Fase )
 ip a muestra la interfaz enp0s3 presente pero sin IPv asignada — comportamiento
esperado no un fallo
 Ambas VMs se apagaron limpiamente ( VBoxManage list runningvms no las muestra
activas)
 VBoxManage snapshot "bdd-nodo01" list y el equivalente para bdd-nodo02 muestran el
snapshot fase05-completa 
 El estudiante puede explicar por qué no hay IP ni acceso a internet en este punto y por
qué eso no impide considerar la fase exitosa
7

F. Problemas comunes y soluciones
| Problema | Causa probable | Solución |
| -------- | -------------- | -------- |
La VM vuelve a  La ISO no se expulsó  Apagar la VM y ejecutar el comando D para
arrancar el  automáticamente y  desmontar la ISO volver a iniciar
| instalador  | sigue teniendo prioridad  |     |
| ----------- | ------------------------- | --- |
| después de  | de arranque               |     |
“Reboot Now”
El instalador se  Está intentando verificar  Esperar a que expire el timeout (– minutos
queda  la conectividad a internet  y elegir continuar sin verificar o si el
“congelado” en la  que no existe en la red  instalador lo permite seleccionar
pantalla de  Host-Only explícitamente “Continue without network”
mirror/red durante
varios minutos
No se puede  El controlador SATA o el  Apagar la VM revisar con  VBoxManage
seleccionar “Use  .vdi  no quedaron  showvminfo "bdd-nodo01"  que el disco esté
an entire  correctamente adjuntados  en  port 0, device 0  volver a adjuntarlo si
| disk” porque  | en la Fase  | es necesario |
| ------------- | ------------ | ------------ |
no aparece
ningún disco
La pantalla del  Memoria de video (VRAM)  Apagar la VM y aumentar VRAM con
instalador se ve  insuficiente para la  VBoxManage modifyvm "bdd-nodo01" --vram
cortada o con  resolución que intenta usar  32  luego reiniciar la instalación
| artefactos  | VirtualBox |     |
| ----------- | ---------- | --- |
visuales
Después de  No se marcó la casilla  Dentro de la VM instalar manualmente con
instalar  “Install OpenSSH server”  sudo apt update && sudo apt install
systemctl  durante la instalación openssh-server  (requiere red temporal si
status ssh  no  no hay red disponible reinstalar el sistema
| existe o el      |     | repitiendo el Paso  y marcando la casilla  |
| ---------------- | --- | ------------------------------------------- |
| servicio no está |     | correctamente)                              |
El teclado dentro  Distribución de teclado  Verificar la distribución elegida en el Paso 
de la ventana de  seleccionada en el  puede corregirse después con  sudo dpkg-
la VM escribe  instalador no coincide con el  reconfigure keyboard-configuration
| caracteres  | teclado físico | dentro de la VM |
| ----------- | -------------- | --------------- |
distintos a los
presionados
La VM no  Cuelgue poco frecuente  Usar  VBoxManage controlvm "bdd-nodo01"
responde al  sudo  del invitado durante el  acpipowerbutton  si tampoco responde
poweroff  ni a  primer arranque VBoxManage controlvm "bdd-nodo01"
| ningún comando |     | poweroff  como último recurso (apagado  |
| -------------- | --- | --------------------------------------- |
forzado no recomendado como práctica
habitual)
8

G. Checklist de validación
Monté la ISO verificada de Ubuntu Server 24.04 LTS en la unidad óptica de  bdd-nodo01 .
Completé la instalación de Subiquity en  bdd-nodo01 , configurando el nombre de host
| como  bdd-nodo01 | .   |     |     |     |
| ---------------- | --- | --- | --- | --- |
Marqué la casilla “Install OpenSSH server” durante la instalación de  bdd-nodo01 .
| Usé particionado guiado (“Use an entire disk”) con LVM en  |     |     |     | .   |
| ---------------------------------------------------------- | --- | --- | --- | --- |
bdd-nodo01
| No marqué ningún snap destacado en  |     |     | .   |     |
| ----------------------------------- | --- | --- | --- | --- |
bdd-nodo01
Retiré correctamente el medio de instalación y   arranca directo al login de
bdd-nodo01
Ubuntu Server.
Verifiqué  hostnamectl ,  lsb_release -a  y  systemctl status ssh  dentro de  bdd-
.
nodo01
Repetí los 7 puntos anteriores exitosamente para  .
bdd-nodo02
Usé el mismo nombre de usuario administrador en ambos nodos.
| Apagué ambas VMs de forma ordenada ( |     |     |  dentro de cada una). |     |
| ------------------------------------ | --- | --- | --------------------- | --- |
sudo poweroff
| Tomé el snapshot  |                 |  en        |  y en      | .   |
| ----------------- | --------------- | ---------- | ---------- | --- |
|                   | fase05-completa | bdd-nodo01 | bdd-nodo02 |     |
Puedo explicar por qué ninguna VM tiene IP ni acceso a internet en este punto, y por qué
eso es lo esperado.
Preparación para la siguiente fase
La Fase 6: Configuración de IP estática dentro de los nodos requerirá:
• Ambas VMs instaladas con OpenSSH activo y snapshot  fase05-completa  tomado (esta
fase)
• El plan de direccionamiento IP definido en la Fase  (sección C):
bdd-nodo01 →
| 192.168.56.101 |   bdd-nodo02 → 192.168.56.102 |     |    |     |
| -------------- | ------------------------------ | --- | --- | --- |
• Acceso a la consola gráfica de cada VM en VirtualBox ya que la configuración de red
estática se hará editando archivos de Netplan directamente dentro de cada nodo antes de
que el acceso por SSH esté disponible
9