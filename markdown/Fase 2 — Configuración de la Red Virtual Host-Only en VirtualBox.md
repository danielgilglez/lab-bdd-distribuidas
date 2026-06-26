Fase 2 — Configuración de la Red
Virtual Host-Only en VirtualBox
Continuación directa de la Fase 0 (planeación). Esta fase no crea ninguna máquina virtual
todavía; solo prepara la red sobre la cual vivirán todos los nodos a partir de la Fase 3. Se
asume que la Fase 1 (instalación de VirtualBox) ya está completa.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar las diferencias entre los cuatro modos de red de VirtualBox NAT Bridged Internal
Network y Host-Only
 Justificar a fondo —como se prometió en la Fase — por qué este laboratorio usa Host-
Only Adapter y no NAT ni Bridged
 Crear y/o verificar el adaptador Host-Only ( vboxnet0 o en Windows “VirtualBox Host-
Only Ethernet Adapter”) desde el VirtualBox Network Manager
 Configurar manualmente la dirección IPv y la máscara de subred del adaptador Host-Only
conforme al plan de direccionamiento de la Fase  (/)
 Decidir y aplicar la desactivación del servidor DHCP integrado de VirtualBox dejando el
camino preparado para el direccionamiento estático que se aplicará dentro de cada VM en
la Fase 
 Verificar desde el host que la red está activa y operando correctamente antes de
construir cualquier nodo
B. Conceptos teóricos necesarios
1. Los cuatro modos de red en VirtualBox.
• NAT Cada VM recibe una red privada propia y sale a internet a través de una traducción
de direcciones que hace VirtualBox igual que un router doméstico Las VMs normalmente
no se ven entre sí ni el host las ve directamente Es el modo por defecto para “una VM
aislada que solo necesita internet”
• Bridged La VM se conecta directamente a la tarjeta de red física del host y obtiene una IP
de la misma red que el equipo físico (por ejemplo la red Wi-Fi del salón o la red
doméstica) Es el modo más “real” pero también el más riesgoso para un laboratorio
expone los nodos a cualquier otro dispositivo de esa red y depende de la configuración del
router/DHCP externo algo que no controlamos
1

• Internal Network Crea una red completamente aislada en la que solo las VMs se ven entre
sí ni siquiera el host tiene acceso a ella Útil para simular un segmento de red totalmente
privado pero inconveniente aquí porque necesitaremos administrar los nodos desde el
host (SSH DBeaver scripts)
• Host-Only Crea una red virtual interna que conecta el host con todas las VMs pero las
aísla de la red física externa Es el punto medio ideal para este laboratorio
2. Por qué Host-Only es la elección correcta aquí.
• Aislamiento el laboratorio no depende de ni interfiere con la red Wi-Fi/Ethernet real del
salón o de casa
• Visibilidad bidireccional host-VM el host (Windows) puede conectarse a cada nodo por
SSH DBeaver etc porque ambos comparten el mismo segmento virtual
• Control total de direccionamiento como el laboratorio depende de IPs fijas para que la
replicación y los nombres de host no se rompan entre reinicios necesitamos un segmento
de red que no dependa de un router externo ni de un DHCP ajeno
• Repetibilidad cualquier estudiante que siga esta guía obtiene exactamente la misma
topología de red (/) sin importar a qué red física esté conectado
su equipo
3. El servidor DHCP integrado de VirtualBox.
Por defecto, cuando se crea un adaptador Host-Only, VirtualBox también activa un pequeño
servidor DHCP asociado (normalmente sirviendo el rango .100 – .254 ). Si lo dejáramos
activo, cada VM podría recibir una IP diferente en cada arranque, lo cual es inaceptable para
un sistema distribuido: la replicación maestro-esclavo, los nombres de host y los scripts de
conexión dependen de que cada nodo tenga siempre la misma IP. Por eso esta fase termina
desactivando ese DHCP; las IPs estáticas reales se asignarán dentro de cada VM hasta la
Fase 6, pero el camino se prepara desde ahora.
4. vboxnet0 vs. nombres de adaptador en Windows.
En Linux/macOS, VirtualBox nombra a los adaptadores Host-Only como vboxnet0 , vboxnet1 ,
etc. En Windows, el mismo concepto aparece en el sistema operativo como una tarjeta de red
llamada “VirtualBox Host-Only Ethernet Adapter” (visible en el Panel de Control o en Get-
NetAdapter ), aunque VirtualBox internamente sigue refiriéndose a ella con un nombre técnico
equivalente. Ambos términos se usan de forma intercambiable en esta guía.
2

C. Procedimiento paso a paso
Paso 1 — Abrir el Network Manager de VirtualBox.
En la ventana principal de VirtualBox: Herramientas (ícono superior) → Network Manager →
pestaña Host-only Networks (en versiones más antiguas: Archivo → Preferencias de
Host → Red ).
Paso 2 — Verificar si ya existe un adaptador Host-Only por defecto.
VirtualBox suele crear uno automáticamente al instalarse. Si ya aparece uno en la lista, se
reutiliza; si la lista está vacía, se crea uno nuevo con el botón Crear .
Paso 3 — Configurar la IPv4 del adaptador.
Seleccionar el adaptador → pestaña Adapter → configurar:
• Dirección IPv: 192.168.56.1
• Máscara de red IPv: 255.255.255.0
Esto coincide exactamente con la IP del host definida en la tabla de direccionamiento de la
Fase 0 (C.3).
Paso 4 — Desactivar el servidor DHCP del adaptador.
En la misma ventana, pestaña DHCP Server → desmarcar la casilla Habilitar servidor
(Enable Server). Confirmar/Aplicar.
Si esta casilla no se puede desmarcar desde la interfaz gráfica en tu versión de VirtualBox,
usa el comando de la sección E.3 para eliminarlo por línea de comandos.
Paso 5 — Aplicar y cerrar.
Guardar los cambios y cerrar el Network Manager.
Paso 6 — Verificar desde Windows que el adaptador quedó activo.
Ejecutar los comandos de la sección E.1 para confirmar que el sistema operativo ve la tarjeta
“VirtualBox Host-Only Ethernet Adapter” con la IP 192.168.56.1 .
Paso 7 — Verificar desde VirtualBox (línea de comandos) que la configuración
quedó guardada.
Ejecutar el comando de la sección E.2 ( VBoxManage list hostonlyifs ) y confirmar IP,
máscara y estado Up .
Paso 8 — Documentar la configuración aplicada.
Crear un archivo de respaldo en la carpeta de documentación ya existente desde la Fase 0,
con el detalle de lo configurado (ver Paso E.4).
3

D. Comandos completos
D.1 Verificar el adaptador Host-Only desde Windows (PowerShell)
PowerShell
Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*VirtualBox
Host-Only*" }
Debe mostrar Status: Up . Para ver la IP asignada:
PowerShell
ipconfig | findstr /C:"VirtualBox" /C:"IPv4"
Buscar manualmente el bloque correspondiente a “Ethernet adapter VirtualBox Host-Only
Network” y confirmar que la dirección IPv4 sea 192.168.56.1 .
D.2 Verificar la configuración desde VirtualBox (CLI)
Desde PowerShell, ubicado en la carpeta de instalación de VirtualBox (o si VBoxManage ya
está en el PATH):
PowerShell
VBoxManage list hostonlyifs
Salida esperada (resumida):
Text
Name: VirtualBox Host-Only Ethernet Adapter
GUID: ...
DHCP: Disabled
IPAddress: 192.168.56.1
NetworkMask: 255.255.255.0
Status: Up
D.3 Eliminar el servidor DHCP por línea de comandos (si el GUI no
lo permite)
Primero listar los servidores DHCP existentes:
4

PowerShell
VBoxManage list dhcpservers
Si aparece uno asociado al adaptador Host-Only, eliminarlo indicando el nombre de interfaz
exacto reportado en el paso anterior:
PowerShell
VBoxManage dhcpserver remove --ifname "VirtualBox Host-Only Ethernet Adapter"
El nombre exacto entre comillas debe coincidir con el que reportó VBoxManage list
hostonlyifs ; puede variar ligeramente entre versiones (por ejemplo, agregando un
número si hay más de un adaptador Host-Only).
D.4 Crear el respaldo de documentación de esta fase
PowerShell
notepad C:\LabBDD\Documentacion\fase2-red.md
Contenido sugerido a pegar y guardar en ese archivo:
Text
Fase 2 - Red Host-Only
IP del host en la red virtual: 192.168.56.1
Mascara: 255.255.255.0
DHCP: deshabilitado (se usaran IPs estaticas desde Fase 6)
Adaptador: VirtualBox Host-Only Ethernet Adapter
Fecha de configuracion: <completar>
E. Verificación de funcionamiento
 Get-NetAdapter muestra el adaptador “VirtualBox Host-Only Ethernet Adapter” con
estado Up 
 ipconfig confirma que ese adaptador tiene la IPv 192.168.56.1 y máscara
255.255.255.0 
 VBoxManage list hostonlyifs confirma la misma IP/máscara y reporta DHCP: Disabled 
5

 VBoxManage list dhcpservers no muestra ningún servidor DHCP activo asociado a este
adaptador
 El estudiante puede explicar sin ver el documento por qué se eligió Host-Only sobre NAT
Bridged e Internal Network
 Existe el archivo C:\LabBDD\Documentacion\fase2-red.md con la configuración
documentada
6

F. Problemas comunes y soluciones (Troubleshooting)
| Problema | Causa probable | Solución |     |     |
| -------- | -------------- | -------- | --- | --- |
No aparece ningún  La instalación de  Reiniciar el host si persiste
| adaptador Host- | VirtualBox no  | reparar la instalación de  |     |     |
| --------------- | -------------- | -------------------------- | --- | --- |
Only en el Network  registró el driver de  VirtualBox desde el instalador
| Manager | red virtual  | ( Repair | )   |     |
| ------- | ------------ | -------- | --- | --- |
correctamente
La casilla “Enable  Bug conocido en  Usar el comando  VBoxManage
Server” del DHCP  algunas versiones de  dhcpserver remove  de la
| no se puede  | VirtualBox | sección D |     |     |
| ------------ | ---------- | ----------- | --- | --- |
desmarcar desde
el GUI
La IP del adaptador  Conflicto con otro  Revisar  Get-NetAdapter
| aparece distinta a  | software de  | completo identificar el  |     |     |
| ------------------- | ------------ | ------------------------- | --- | --- |
192.168.56.1  tras  virtualización que  adaptador en conflicto y si es
reiniciar Windows usa el mismo rango  necesario cambiar el rango del
|     | (VMware  | Host-Only de VirtualBox a uno  |     |     |
| --- | -------- | ------------------------------ | --- | --- |
Workstation
|     |     | libre p ej  | 192.168.57.0/24 |    |
| --- | --- | -------------- | --------------- | --- |
WSL/Hyper-V
actualizando también la tabla de
vEthernet)
IPs de la Fase 
VBoxManage  no se  La carpeta de  Ejecutar el comando desde la
| reconoce como  | instalación de         | carpeta de instalación  |             |      |
| -------------- | ---------------------- | ----------------------- | ----------- | ---- |
| comando        | VirtualBox no está en  | (normalmente            | C:\Program  |      |
|                | el  PATH  del sistema  | Files\Oracle\VirtualBox |             | ) o  |
|                |                        | agregarla al            | PATH        |      |
El host no puede  El adaptador de red  Confirmar en la configuración de
hacer ping a las  de la VM no está  red de la VM que el adaptador
| VMs una vez  | vinculado al Host- | está en modo “Host-only  |     |     |
| ------------ | ------------------ | ------------------------ | --- | --- |
creadas (a futuro  Only correcto o el  Adapter” apuntando al
| Fase +) | firewall de Windows  | adaptador correcto revisar  |     |     |
| -------- | -------------------- | ---------------------------- | --- | --- |
|          | bloquea el segmento  | reglas de firewall           |     |     |
192.168.56.0/24
Al asignar como  La instalación de  Agrege otra tarjeta virtual con
| host-only no  | VirtualBox no  | otra direccion ya que a vgeces  |     |     |
| ------------- | -------------- | ------------------------------- | --- | --- |
arranca la máquina  registró el driver de  el  192.168.56.0/24  esta
| virtual marcando    | red virtual   | bloqueado o trabado |     |     |
| ------------------- | ------------- | -------------------- | --- | --- |
| un error de tarjeta | correctamente |                      |     |     |
G. Checklist de validación
Puedo explicar la diferencia entre los modos NAT, Bridged, Internal Network y Host-Only.
Puedo justificar, con mis propias palabras, por qué este laboratorio usa Host-Only.
7

El adaptador Host-Only existe y tiene la IP 192.168.56.1 / máscara 255.255.255.0 .
Confirmé el estado del adaptador con Get-NetAdapter desde Windows.
Confirmé la configuración con VBoxManage list hostonlyifs desde la línea de
comandos de VirtualBox.
Desactivé (o eliminé) el servidor DHCP asociado a este adaptador.
Verifiqué con VBoxManage list dhcpservers que no queda ningún servidor DHCP activo
en este segmento.
Documenté esta configuración en C:\LabBDD\Documentacion\fase2-red.md .
Preparación para la siguiente fase
La Fase 3 creará los dos primeros nodos ( bdd-nodo01 y bdd-nodo02 ) y requerirá:
• La red Host-Only configurada y verificada en esta fase
• VirtualBox instalado (Fase )
• La ISO de Ubuntu Server descargada (Fase  — nota aunque la numeración de fases del
plan original ubica la descarga de la ISO después en la práctica deberá tenerse lista antes
de poder instalar el sistema operativo en los nodos esto se aclarará explícitamente al
inicio de la Fase )
8