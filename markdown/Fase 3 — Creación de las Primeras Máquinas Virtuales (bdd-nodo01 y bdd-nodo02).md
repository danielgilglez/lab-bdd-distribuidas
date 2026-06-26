Fase 3 — Creación de las Primeras Máquinas
Virtuales (bdd-nodo01 y bdd-nodo02)
Continuación del laboratorio de bases de datos distribuidas. En esta fase se crean las dos
primeras VMs vacías (sin sistema operativo todavía) siguiendo el dimensionamiento y la
convención de nombres definidos en la Fase 0. La instalación del sistema operativo dentro
de ellas corresponde a una fase posterior, una vez descargada la ISO (Fase 4).
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Crear máquinas virtuales vacías en VirtualBox respetando el dimensionamiento de recursos
(vCPU RAM disco) definido en la Fase 
 Aplicar correctamente la convención de nombres bdd-nodoNN al nombrar las VMs dentro
de VirtualBox
 Crear y habilitar la red Host-Only ( vboxnet0 ) que servirá de columna vertebral de
comunicación entre nodos
 Adjuntar el adaptador de red Host-Only a cada VM dejando la configuración de IP estática
pendiente para la fase de red
 Explicar la diferencia entre “crear una VM” (definir hardware virtual CPU RAM disco red)
e “instalar un sistema operativo” dentro de ella
 Verificar mediante línea de comandos que las VMs creadas coinciden exactamente con
lo planeado
 Cerrar la fase con la primera bitácora de snapshot aunque todavía no haya sistema
operativo instalado
B. Teoría necesaria
1. ¿Qué es una VM a nivel de archivos en VirtualBox?
Cada máquina virtual está compuesta, principalmente, por dos tipos de archivo en el host: un
archivo de configuración .vbox (XML legible, describe CPU, RAM, dispositivos, adaptadores
de red) y uno o más archivos de disco virtual .vdi (el contenido del “disco duro” virtual).
Crear una VM, en esta fase, significa generar estos archivos; todavía no contienen un sistema
operativo, son un contenedor de hardware virtual vacío, equivalente a comprar una PC nueva
sin sistema operativo instalado.
2. Disco dinámico vs. disco de tamaño fijo.
1

• Dinámico el archivo .vdi empieza pequeño (unos MB) y crece según se usa hasta el
límite definido Ahorra espacio en el host mientras el laboratorio crece gradualmente
• Fijo reserva todo el espacio desde el inicio es ligeramente más rápido en I/O pero
desperdicia espacio si el nodo no se usa todavía
Para este laboratorio se eligió dinámico (ver tabla C de la Fase ) porque el host
no tiene por qué reservar  GB de inmediato si los nodos – no se activarán hasta
fases avanzadas
3. Chipset y firmware de la VM.
VirtualBox permite elegir chipset (PIIX3 vs. ICH9) y firmware (BIOS vs. EFI). Para Ubuntu
Server LTS moderno, el valor por defecto que ofrece VirtualBox al seleccionar el tipo de
sistema operativo “Linux / Ubuntu (64-bit)“ es adecuado y no requiere ajustes manuales en
este laboratorio.
4. Adaptador de red Host-Only: qué se hace ahora y qué se deja pendiente.
En la Fase 0 se decidió usar Host-Only Adapter en lugar de NAT o Bridged. Esa red virtual
( vboxnet0 ) es un objeto independiente de las VMs: existe a nivel de VirtualBox/host, no
dentro de ninguna máquina. En esta fase:
• Se crea la red Host-Only vboxnet0 con IP de host 192.168.56.1 (coincide con el plan de
direccionamiento de la Fase  sección C)
• Se adjunta el Adaptador  de cada VM a esa red
• No se configura todavía la IP estática dentro de cada VM porque eso requiere un sistema
operativo instalado y arrancado (correspondiente a la Fase ) Por ahora la VM ni siquiera
puede arrancar no tiene OS
5. ¿Por qué crear las VMs antes de tener la ISO de Ubuntu?
Es una separación de responsabilidades: primero se define el “hardware virtual” (esta fase),
después se obtiene el medio de instalación (Fase 4) y finalmente se instala el sistema
operativo sobre el hardware ya definido (fase posterior). Esto refleja cómo se aprovisiona
infraestructura real en un centro de datos: el aprovisionamiento de hardware/VM y la
instalación del sistema operativo suelen ser pasos administrativos distintos.
C. Procedimiento paso a paso
Paso 1 — Verificar que VirtualBox está instalado y operativo.
Confirmar que la Fase 1 (instalación de VirtualBox) quedó completa antes de continuar.
Paso 2 — Crear la red Host-Only vboxnet0 en el host.
Esta red es compartida por todas las VMs del laboratorio; se crea una sola vez.
2

Paso 3 — Crear la VM bdd-nodo01 (vacía).
Usando el dimensionamiento de la Fase 0: 1 vCPU, 1536 MB RAM, 20 GB disco dinámico.
Paso 4 — Adjuntar el disco virtual y el controlador de almacenamiento a bdd-nodo01 .
Paso 5 — Configurar el Adaptador 1 de bdd-nodo01 como Host-Only, enlazado a vboxnet0 .
Paso 6 — Repetir los Pasos 3 a 5 para bdd-nodo02 (mismo dimensionamiento: 1 vCPU, 1536
MB, 20 GB).
Paso 7 — Verificar ambas VMs con VBoxManage list vms y showvminfo .
Paso 8 — Documentar el snapshot inicial de la fase.
Aunque no hay sistema operativo, se recomienda anotar en Snapshots-Notas que ambas VMs
quedaron creadas y verificadas, como punto de partida antes de instalar el OS.
Paso 9 — Validar con el checklist de la sección G.
D. Comandos completos
Todos los comandos se ejecutan en PowerShell, en el host Windows. Se usa VBoxManage ,
la herramienta de línea de comandos de VirtualBox (si no se reconoce el comando, agregar
C:\Program Files\Oracle\VirtualBox al PATH del sistema, o ejecutar desde esa carpeta).
D.1 Crear la red Host-Only vboxnet0
PowerShell
VBoxManage list hostonlyifs
Si no aparece ninguna interfaz todavía, crearla:
PowerShell
VBoxManage hostonlyif create
Asignarle la IP de host planeada en la Fase 0 (192.168.56.1):
PowerShell
VBoxManage hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter" --ip
192.168.56.1 --netmask 255.255.255.0
3

Nota: el nombre exacto de la interfaz ( "VirtualBox Host-Only Ethernet Adapter" , a
veces con un número al final como #2 ) puede variar según cuántas interfaces Host-Only
existan ya en el sistema. Usar el nombre exacto que devolvió list hostonlyifs en el paso
anterior.
D.2 Crear la VM bdd-nodo01
PowerShell
VBoxManage createvm --name "bdd-nodo01" --ostype "Ubuntu_64" --basefolder
"C:\LabBDD\VMs" --register
Configurar CPU y RAM según el dimensionamiento de la Fase 0:
PowerShell
VBoxManage modifyvm "bdd-nodo01" --cpus 1 --memory 1536 --vram 16
Crear el controlador de almacenamiento (SATA) y el disco virtual dinámico de 20 GB:
PowerShell
VBoxManage storagectl "bdd-nodo01" --name "SATA Controller" --add sata --
controller IntelAHCI
VBoxManage createhd --filename "C:\LabBDD\VMs\bdd-nodo01\bdd-nodo01.vdi" --
size 20480 --variant Standard
VBoxManage storageattach "bdd-nodo01" --storagectl "SATA Controller" --port 0
--device 0 --type hdd --medium "C:\LabBDD\VMs\bdd-nodo01\bdd-nodo01.vdi"
Agregar también un controlador IDE/SATA vacío para la futura unidad óptica (se usará en Fase
4 para montar la ISO):
PowerShell
VBoxManage storageattach "bdd-nodo01" --storagectl "SATA Controller" --port 1
--device 0 --type dvddrive --medium emptydrive
Configurar el Adaptador 1 como Host-Only:
PowerShell
VBoxManage modifyvm "bdd-nodo01" --nic1 hostonly --hostonlyadapter1
"VirtualBox Host-Only Ethernet Adapter"
4

D.3 Crear la VM bdd-nodo02
Repetir el mismo bloque, cambiando únicamente el nombre:
PowerShell
VBoxManage createvm --name "bdd-nodo02" --ostype "Ubuntu_64" --basefolder
"C:\LabBDD\VMs" --register
VBoxManage modifyvm "bdd-nodo02" --cpus 1 --memory 1536 --vram 16
VBoxManage storagectl "bdd-nodo02" --name "SATA Controller" --add sata --
controller IntelAHCI
VBoxManage createhd --filename "C:\LabBDD\VMs\bdd-nodo02\bdd-nodo02.vdi" --
size 20480 --variant Standard
VBoxManage storageattach "bdd-nodo02" --storagectl "SATA Controller" --port 0
--device 0 --type hdd --medium "C:\LabBDD\VMs\bdd-nodo02\bdd-nodo02.vdi"
VBoxManage storageattach "bdd-nodo02" --storagectl "SATA Controller" --port 1
--device 0 --type dvddrive --medium emptydrive
VBoxManage modifyvm "bdd-nodo02" --nic1 hostonly --hostonlyadapter1
"VirtualBox Host-Only Ethernet Adapter"
D.4 Listar y verificar las VMs creadas
PowerShell
VBoxManage list vms
Salida esperada:
Text
"bdd-nodo01" {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
"bdd-nodo02" {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
Ver el detalle completo de configuración de una VM:
PowerShell
VBoxManage showvminfo "bdd-nodo01"
Listar los discos virtuales registrados:
5

PowerShell
VBoxManage list hdds
E. Verificación de funcionamiento
 VBoxManage list vms  muestra exactamente  bdd-nodo01  y  bdd-nodo02  (y ninguna otra
VM no planeada)
 VBoxManage showvminfo "bdd-nodo01"  reporta  CPU  MB de memoria adaptador
| de red  en modo            | hostonly |  enlazado a la interfaz correcta |     |     |
| --------------------------- | -------- | --------------------------------- | --- | --- |
|  Lo mismo se cumple para  |          | bdd-nodo02                        |    |     |
 VBoxManage list hdds  muestra dos discos  .vdi  de  GB (tamaño lógico) ubicados
| dentro de  | C:\LabBDD\VMs\ |                                       |     |     |
| ---------- | -------------- | -------------------------------------- | --- | --- |
|          |                |  muestra la interfaz Host-Only con IP  |     |    |
VBoxManage list hostonlyifs 192.168.56.1
 Al abrir VirtualBox Manager (interfaz gráfica) ambas VMs aparecen apagadas (estado
“Apagada”) sin sistema operativo instalado listas para la Fase 
 El estudiante puede explicar por qué ninguna de las dos VMs puede arrancar todavía un
sistema operativo funcional
6

F. Problemas comunes y soluciones
7

| Problema |         | Causa probable |     | Solución                     |     |     |
| -------- | ------- | -------------- | --- | ---------------------------- | --- | --- |
|          |  no se  | La carpeta de  |     | Ejecutar los comandos desde  |     |     |
VBoxManage
| reconoce como  |     | instalación no está en  |     | C:\Program              |     |      |
| -------------- | --- | ----------------------- | --- | ----------------------- | --- | ---- |
| comando        |     | el PATH de Windows      |     | Files\Oracle\VirtualBox |     |  o  |
agregar esa ruta al PATH del
sistema y reabrir PowerShell
Error al crear la  Controlador de red  Reinstalar/reparar VirtualBox
interfaz Host-Only  virtual de VirtualBox  desde el instalador oficial
| (   |     |   no instalado  |     | verificar en “Conexiones de red”  |     |     |
| --- | --- | --------------- | --- | --------------------------------- | --- | --- |
hostonlyif create
| falla) |     | correctamente o    |     | de Windows que aparezca el  |     |     |
| ------ | --- | ------------------- | --- | --------------------------- | --- | --- |
|        |     | conflicto con otro  |     | adaptador Host-Only         |     |     |
software de
virtualización
|     |  falla  | Se ejecutó el  |     | Eliminar la VM duplicada con  |     |     |
| --- | ------- | -------------- | --- | ----------------------------- | --- | --- |
createvm
| indicando que la VM  |     | comando dos veces o  |     |     |     |     |
| -------------------- | --- | --------------------- | --- | --- | --- | --- |
VBoxManage unregistervm
| ya existe |     | quedó un registro  |     |     |     |  antes  |
| --------- | --- | ------------------ | --- | --- | --- | ------- |
"bdd-nodo01" --delete
|               |         | previo de prueba |           | de volver a crearla |     |     |
| ------------- | ------- | ---------------- | --------- | ------------------- | --- | --- |
| storageattach |  falla  | La ruta del      | .vdi  no  | Verificar que       |     |     |
con error de archivo  coincide exactamente  C:\LabBDD\VMs\bdd-nodo01\
no encontrado con la usada en  exista (VirtualBox normalmente
|     |     | createhd          |  o la  | la crea automáticamente con  |     |             |
| --- | --- | ----------------- | ------- | ---------------------------- | --- | ----------- |
|     |     | carpeta no existe |         | createvm --register          |     | ) revisar  |
rutas exactas
La VM aparece con   El comando  Volver a ejecutar  modifyvm
MB de RAM o  CPUs  modifyvm  se ejecutó  explícitamente y confirmar con
| en  showvminfo |     | antes de que  |             | showvminfo |     |     |
| -------------- | --- | ------------- | ----------- | ---------- | --- | --- |
|                |     | createvm      |  terminara  |            |     |     |
de registrar la VM o
hubo un error
silencioso
El adaptador de red  El comando  modifyvm  Volver a ejecutar  modifyvm  con
no aparece como  --nic1 hostonly  no  el nombre exacto de la interfaz
| hostonly         |  sino como  | se ejecutó o se      |     | devuelto por           | list           |     |
| ---------------- | ----------- | -------------------- | --- | ---------------------- | -------------- | --- |
| nat  (valor por  |             | ejecutó con un       |     | hostonlyifs            |  (cuidado con  |     |
| defecto)         |             | nombre de adaptador  |     | mayúsculas y espacios) |                |     |
incorrecto
Espacio en disco del  Confusión entre  Verificar con el explorador de
host crece más de lo  tamaño lógico ( GB)  archivos el tamaño real del
esperado a pesar de  y tamaño real  .vdi  si ya pesa varios GB sin
usar disco dinámico ocupado en esta  haber instalado nada revisar
|     |     | fase sin OS instalado  |           | que se usó  | --variant         |     |
| --- | --- | ------------------------ | --------- | ----------- | ----------------- | --- |
|     |     | el  .vdi                 |  debería  | Standard    |  (dinámico) y no  |     |
|     |     | pesar solo unos KB-      |           | Fixed       |                   |     |
MB
8

G. Checklist de validación
La red Host-Only vboxnet0 existe y tiene la IP 192.168.56.1 asignada.
La VM bdd-nodo01 existe, con nombre exacto según convención.
La VM bdd-nodo01 tiene 1 vCPU, 1536 MB de RAM y un disco dinámico de 20 GB.
La VM bdd-nodo01 tiene su Adaptador 1 en modo Host-Only, enlazado a la interfaz
correcta.
La VM bdd-nodo01 tiene una unidad óptica vacía lista para montar la ISO en la Fase 4.
Se repitieron y verificaron los 4 puntos anteriores para bdd-nodo02 .
VBoxManage list vms muestra únicamente las dos VMs esperadas, sin duplicados ni VMs
de prueba sobrantes.
Ambos discos .vdi están ubicados dentro de C:\LabBDD\VMs\ , conforme a la estructura
de carpetas de la Fase 0.
El estudiante puede explicar la diferencia entre “crear una VM” e “instalar un
sistema operativo”.
Se documentó el estado de esta fase en Snapshots-Notas como punto de partida antes
de la instalación del sistema operativo.
9