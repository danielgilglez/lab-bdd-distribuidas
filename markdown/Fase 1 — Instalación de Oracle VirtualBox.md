Fase 1 — Instalación de Oracle VirtualBox

Continuación directa de la Fase 0. Se asume que ya existe la estructura de carpetas

C:\LabBDD  y que se resolvió cualquier conflicto de virtualización (BIOS/UEFI o Hyper-V)

detectado previamente.

A. Objetivos de aprendizaje

Al finalizar esta fase, el estudiante será capaz de:



Explicar qué es un hipervisor de Tipo  y diferenciarlo conceptualmente de uno de Tipo 



Descargar e instalar correctamente Oracle VirtualBox en un host Windows



Instalar el VirtualBox Extension Pack y entender por qué es un componente separado con

licencia distinta



Configurar la carpeta predeterminada de máquinas virtuales para que apunte a

C:\LabBDD\VMs  en lugar de la ruta por defecto



Verificar mediante la interfaz gráfica y mediante línea de comandos ( VBoxManage ) que la

instalación quedó funcional



Reconocer los componentes principales de la interfaz de VirtualBox que se usarán en fases

posteriores (Administrador de VMs Administrador de medios Administrador de redes)

B. Conceptos teóricos necesarios

1. Hipervisor. Software que permite crear y ejecutar máquinas virtuales sobre un hardware

físico (host).

Tipo  (bare-metal) se ejecuta directamente sobre el hardware sin sistema operativo

anfitrión por debajo (ej VMware ESXi Hyper-V en modo servidor KVM) Suele usarse en

centros de datos

Tipo  (hosted) se ejecuta como una aplicación dentro de un sistema operativo anfitrión

ya existente (ej VirtualBox VMware Workstation) Es el modelo de este laboratorio

Windows es el host y VirtualBox corre como un programa más dentro de él

2. VirtualBox como producto. Es un hipervisor de Tipo 2 de propósito general, mantenido por

Oracle, que permite crear máquinas virtuales x86_64 con soporte para Windows, Linux, macOS

(Intel) y Solaris como sistemas invitados.

••3. Paquete base vs. Extension Pack. VirtualBox se distribuye en dos partes con

licencias distintas:

El paquete base es software libre bajo licencia GNU GPL v

El Extension Pack es un componente adicional de licencia propietaria (gratuita para uso

personal/educativo pero no de código abierto) que agrega soporte para dispositivos USB

/ Remote Desktop Protocol (RDP) cifrado de disco y arranque PXE para tarjetas de

red Intel En este laboratorio se instalará porque facilitará el uso de USB y opcionalmente

acceso remoto a las VMs en fases posteriores

4. ¿Por qué versión 7.2.x? La rama 7.2 es, a la fecha de esta guía, la rama en mantenimiento

activo de VirtualBox; las ramas 7.1, 7.0 y 6.1 ya no reciben soporte. Se recomienda siempre

instalar la última versión estable de la rama activa, descargada únicamente desde el

sitio oficial.

5.  VBoxManage . Herramienta de línea de comandos incluida con VirtualBox que permite hacer,

mediante scripts, todo lo que la interfaz gráfica permite hacer manualmente (crear VMs,

discos, snapshots, redes, etc.). Se usará intensivamente a partir de la Fase 3 para automatizar

la creación de nodos.

C. Procedimiento paso a paso

Paso 1 — Descargar el instalador desde el sitio oficial.

Ir a  https://www.virtualbox.org/wiki/Downloads  (nunca desde portales de terceros tipo

Softonic/Uptodown, para evitar instaladores modificados). Descargar el paquete para

“Windows hosts” de la rama estable más reciente (7.2.x al momento de escribir esta guía).

Paso 2 — Descargar el Extension Pack correspondiente.

En la misma página de descargas, descargar “VirtualBox Extension Pack”. Es un único archivo

.vbox-extpack  válido para todas las plataformas; debe coincidir en número de versión

mayor.menor con el instalador base (ej. ambos 7.2.x).

Paso 3 — Ejecutar el instalador base con permisos de administrador.

Doble clic en el  .exe  descargado → “Sí” en el control de cuentas de usuario (UAC). Durante el

asistente:

Dejar las características marcadas por defecto (VirtualBox USB Support VirtualBox

Networking VirtualBox Python x/x Support si aparece)

Cuando pregunte por la ruta de instalación del programa (no de las VMs) se puede dejar la

ruta por defecto ( C:\Program Files\Oracle\VirtualBox\ ) esto es distinto de dónde

vivirán los discos de las VMs que se configura en el Paso 

••••Aceptar la advertencia de “se perderá temporalmente la conectividad de red” (VirtualBox

instala adaptadores de red virtuales puede desconectar brevemente el Wi-Fi/Ethernet del

host durante la instalación)

Finalizar e iniciar VirtualBox al terminar

Paso 4 — Instalar el Extension Pack desde la interfaz gráfica.

Con VirtualBox abierto:  Archivo → Herramientas → Administrador de medios  no es la ruta

correcta para esto; en su lugar ir a  Archivo → Preferencias → Extensiones → ícono "+"

(Agregar paquete) , seleccionar el archivo  .vbox-extpack  descargado en el Paso 2, dar clic

en “Instalar” y aceptar la licencia (PUEL — Personal Use and Evaluation License).

Paso 5 — Verificar la versión instalada.

En la interfaz:  Ayuda → Acerca de VirtualBox . Debe coincidir la versión del programa con la

del Extension Pack (ver comandos en sección D para verificación por línea de comandos).

Paso 6 — Redirigir la carpeta predeterminada de máquinas virtuales.

Por defecto, VirtualBox guarda discos y configuraciones en  C:\Users\<usuario>\VirtualBox

VMs\ . Para mantener todo el laboratorio organizado dentro de  C:\LabBDD , cambiar esta ruta:

Archivo → Preferencias → General → Carpeta predeterminada de máquinas  → cambiar a

C:\LabBDD\VMs .

Importante: este cambio solo afecta a las VMs que se creen después de modificarlo; no

mueve nada existente (en este punto no debería haber ninguna VM creada todavía).

Paso 7 — Revisar el Administrador de redes (sin crear nada todavía).

Herramientas → Red  (o  Archivo → Herramientas → Administrador de redes de host ).

Simplemente confirmar que la pestaña “Adaptadores solo-anfitrión” existe y está vacía. La

creación del adaptador  vboxnet0  con la IP  192.168.56.1  planeada en la Fase 0 se hará

formalmente en la Fase 2, no aquí.

Paso 8 — Cerrar snapshot conceptual de la fase.

Como todavía no existen VMs, no hay nada que snapshotear en VirtualBox en este punto. En

su lugar, anotar en  C:\LabBDD\Snapshots-Notas\fase01-notas.txt  la versión exacta

instalada (base + Extension Pack) y la fecha, para trazabilidad.

••D. Comandos

D.1 Verificar la versión de VirtualBox desde PowerShell

PowerShell

& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version

Salida esperada (ejemplo de formato, el número exacto dependerá de la versión descargada):

Text

7.2.8r173730

D.2 Agregar VBoxManage al PATH (opcional, recomendado)

Para no escribir la ruta completa cada vez, en PowerShell como administrador:

PowerShell

[Environment]::SetEnvironmentVariable(

  "Path",

  $env:Path + ";C:\Program Files\Oracle\VirtualBox",

  [EnvironmentVariableTarget]::Machine

)

Cerrar y volver a abrir PowerShell para que tome efecto. Después de esto, el comando se

simplifica a:

PowerShell

VBoxManage --version

D.3 Listar los Extension Packs instalados

PowerShell

VBoxManage list extpacks

Debe mostrar el paquete  Oracle VM VirtualBox Extension Pack  con número de versión y

revisión ( r ) idéntico al del paso D.1.

D.4 Confirmar que aún no existen máquinas virtuales (esperado en
esta fase)

PowerShell

VBoxManage list vms

Salida esperada: vacío (todavía no se ha creado ningún nodo; eso corresponde a la Fase 3).

D.5 Confirmar la carpeta predeterminada configurada en el Paso 6

PowerShell

VBoxManage list systemproperties | findstr /C:"Default machine folder"

Debe mostrar  C:\LabBDD\VMs .

E. Verificación de funcionamiento



VBoxManage --version  se ejecuta sin errores y reporta una versión de la rama x (o la

rama estable vigente al momento de instalar)



VBoxManage list extpacks  muestra el Extension Pack instalado con número de versión

coincidente con el del paquete base



La interfaz gráfica de VirtualBox abre sin mensajes de error ni advertencias de

drivers faltantes



Archivo → Preferencias → General → Carpeta predeterminada de máquinas  muestra

C:\LabBDD\VMs 



VBoxManage list vms  regresa vacío (correcto para esta fase todavía no se crean nodos)



Existe el archivo  C:\LabBDD\Snapshots-Notas\fase01-notas.txt  con la versión instalada

y la fecha

F. Problemas comunes y soluciones

Problema

Causa probable

Solución

El instalador

Antivirus o políticas

Agregar excepción temporal para el

falla con error
de “Python
Core” o

“Network
Interfaces” a
mitad de
instalación

Mensaje  VT-x

is not

available  al

intentar usar
VirtualBox
después de

instalarlo

de grupo bloquean la
instalación de drivers de
red virtuales

instalador en el antivirus institucional
reintentar instalación como administrador

Hyper-V activo entrando en
conflicto o virtualización
deshabilitada en BIOS (no

resuelto desde la Fase )

Revisar de nuevo  bcdedit /enum |
findstr hypervisorlaunchtype  (ver
Fase  sección E) actualizar a la
última versión x que tiene mejor
coexistencia con Hyper-V

El Extension

Se descargó una versión del

Verificar ambos números de versión en

Pack no aparece
o aparece como
“no compatible”

Extension Pack que
no coincide con la
versión mayormenor del
paquete base

virtualbox.org/wiki/Downloads 

deben coincidir en  X.Y  (ej ambos x)

La red se
desconecta
brevemente

durante la
instalación y no
vuelve sola

El adaptador de red físico
tarda en re-negociar tras la
instalación de los drivers de

Esperar – minutos o
deshabilitar/habilitar el adaptador
de red físico desde el Administrador

VirtualBox

de dispositivos

VBoxManage  no

se reconoce
como comando

No se agregó al PATH
(paso D) o no se reinició
la terminal después

Cerrar todas las ventanas de
PowerShell/CMD abiertas y abrir una
nueva o usar la ruta completa como

de agregarlo

en D

El instalador
pide reiniciar

Windows

Es normal cuando se
instalan por primera vez los

Reiniciar y volver a abrir VirtualBox
para continuar

drivers de red/USB de
VirtualBox

G. Checklist de validación

Descargué VirtualBox únicamente desde  virtualbox.org , rama estable vigente (no de

portales de terceros).

Descargué el Extension Pack con número de versión  X.Y  coincidente con el paquete

base.

Instalé VirtualBox con permisos de administrador y reinicié si fue solicitado.

Instalé el Extension Pack desde  Preferencias → Extensiones  y acepté la licencia PUEL.

VBoxManage --version  y  VBoxManage list extpacks  se ejecutan correctamente desde

PowerShell.

Cambié la carpeta predeterminada de máquinas a  C:\LabBDD\VMs .

Confirmé que  VBoxManage list vms  está vacío (todavía no toca crear nodos).

Documenté la versión instalada en  C:\LabBDD\Snapshots-Notas\fase01-notas.txt .

Puedo explicar la diferencia entre un hipervisor Tipo 1 y Tipo 2, y por qué VirtualBox es

Tipo 2.

Puedo explicar por qué el Extension Pack es un componente separado, con licencia

distinta al paquete base.

H. Preparación para la siguiente fase

La Fase 2: Configuración de la red Host-Only requerirá:

VirtualBox y su Extension Pack ya instalados y verificados (esta fase)

Comprender el plan de direccionamiento IP definido en la Fase  sección C

( 192.168.56.0/24 )

Tener claro por qué se eligió Host-Only sobre NAT o Bridged (mencionado en Fase  se

justificará a fondo en Fase )

Todavía no se crea ninguna máquina virtual; eso corresponde a la Fase 3, una vez configurada

la red.

•••