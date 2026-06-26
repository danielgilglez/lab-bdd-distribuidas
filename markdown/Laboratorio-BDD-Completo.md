Fase 0 — Planeación y Diseño del
Laboratorio de Bases de Datos Distribuidas
Laboratorio académico construido sobre una sola computadora física, con Oracle
VirtualBox y Ubuntu Server LTS + MariaDB. Sin Docker, sin Kubernetes.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar qué es un sistema de bases de datos distribuidas y diferenciarlo de un
sistema centralizado
 Identificar los temas que se cubrirán a lo largo del laboratorio (replicación física lógica
fragmentación horizontal/vertical/híbrida consultas distribuidas transparencia tolerancia
a fallos)
 Diseñar la arquitectura objetivo final del laboratorio antes de tocar una sola
máquina virtual
 Calcular los requisitos de hardware del equipo anfitrión (host) necesarios para soportar el
crecimiento gradual del laboratorio
 Definir una convención de nombres un esquema de direccionamiento IP y un plan de
crecimiento por fases
 Justificar por qué la planeación previa reduce el retrabajo en fases posteriores
B. Conceptos teóricos necesarios
1. Sistema de bases de datos distribuidas (SBDD). Conjunto de nodos interconectados, cada
uno con su propio motor de base de datos, que se presentan ante el usuario como si fueran un
único sistema lógico.
2. Replicación física vs. lógica.
• Física se replican los cambios a nivel de bloques/eventos binarios del motor de
almacenamiento (en MariaDB vía binlog row-based o las posiciones GTID) Es la base de la
alta disponibilidad clásica maestro-esclavo
• Lógica se replican declaraciones SQL o eventos lógicos interpretables (statement-based
replication o herramientas de replicación multi-maestro como Galera) Permite topologías
más flexibles (multi-maestro bidireccional)

3. Fragmentación (particionamiento de datos).
• Horizontal se dividen las filas de una tabla entre varios nodos (ej clientes del norte en un
nodo del sur en otro)
• Vertical se dividen las columnas de una tabla entre varios nodos (ej datos personales en
un nodo datos financieros en otro)
• Híbrida combinación de ambas estrategias
4. Transparencia de distribución. Capacidad del sistema de ocultar al usuario/aplicación el
hecho de que los datos están distribuidos: transparencia de fragmentación, de ubicación, de
replicación y de concurrencia.
5. Teorema CAP. En presencia de una partición de red (P), un sistema distribuido debe elegir
entre Consistencia © y Disponibilidad (A). Este laboratorio nos permitirá observar este
compromiso de forma práctica, no solo teórica.
6. Tolerancia a fallos y recuperación. Capacidad del sistema de seguir operando (o de
recuperarse limpiamente) ante la caída de uno o varios nodos.
C. Arquitectura utilizada
C.1 Arquitectura física (la que existe hoy)
Una sola laptop/PC con Windows ejecuta VirtualBox. Cada “nodo” del sistema distribuido es,
en realidad, una máquina virtual Ubuntu Server dentro de ese mismo equipo. Una red virtual
interna (Host-Only) interconecta las VMs entre sí y con el host, simulando una red de centro
de datos.

C.2 Arquitectura lógica objetivo (a dónde llegaremos, gradualmente)
| Nodo | Hostname  | Rol funcional (fase en que se activa) |
| ---- | --------- | ------------------------------------- |
propuesto
|    |     | Maestro de replicación física (Fase ) |
| --- | --- | --------------------------------------- |
bdd-nodo01
|    | bdd-nodo02 | Esclavo de replicación física (Fase )              |
| --- | ---------- | ---------------------------------------------------- |
|    |            | Nodo de replicación lógica / multi-maestro (Fase ) |
bdd-nodo03
|    | bdd-nodo04 | Fragmento horizontal A (Fase ) |
| --- | ---------- | -------------------------------- |
|    | bdd-nodo05 | Fragmento horizontal B (Fase ) |
 bdd-nodo06 Coordinador de consultas distribuidas / fragmentación
vertical-híbrida (Fases –)
 (opcional) bdd-cliente Estación cliente externa para pruebas de transparencia
(Fase –)
Importante: no crearemos los 7 nodos ahora. Esta tabla es el mapa final. El laboratorio
crecerá de 2 nodos (Fase 3) hasta 6–7 nodos (Fase 16), apagando con snapshots los nodos
que no se usen en cada sesión para ahorrar recursos del host.

C.3 Plan de direccionamiento IP (reservado para cuando configuremos
la red)
| Nodo           | IP planeada  | Tipo de red |     |
| -------------- | ------------ | ----------- | --- |
| Host (Windows) |  | Host-Only   |     |
Adapter
(vboxnet)
| bdd-nodo  |  | Estática |     |
| ----------- | -------------- | -------- | --- |
| bdd-nodo  |  | Estática |     |
| bdd-nodo  |  | Estática |     |
| bdd-nodo  |  | Estática |     |
| bdd-nodo  |  | Estática |     |
| bdd-nodo  |  | Estática |     |
| bdd-cliente |  | Estática |     |
Se elige Host-Only Adapter (no NAT, no Bridged) porque: aísla el laboratorio de la red
física/Wi-Fi real (seguridad y evita interferir con la red del salón), y permite que el host
(Windows) y todas las VMs se vean entre sí, lo cual facilita administración con SSH, DBeaver,
etc. Esta decisión se justificará a fondo en la Fase 2.
C.4 Dimensionamiento de recursos por nodo (referencia para Fase 3)
| Nodo               | vCPU | RAM     | Disco (dinámico) |
| ------------------ | ---- | ------- | ---------------- |
| bdd-nodo /  /  |     |  MB |  GB            |
 / 
| bdd-nodo /  |    |  MB |  GB |
| --------------- | --- | ------- | ----- |
| bdd-cliente     |    |  MB |  GB |
Total si todos los nodos corrieran simultáneamente: ~7 vCPU, ~9.25 GB RAM, ~120 GB disco
(asignación dinámica, no se ocupa todo de inmediato).
D. Procedimiento paso a paso
Paso 1 — Verificar que el equipo host cumple los requisitos mínimos.
Antes de instalar nada, confirmamos que la PC física puede soportar VirtualBox y varias VMs
Linux corriendo a la vez.

Requisitos mínimos recomendados:
• CPU de  núcleos físicos o más con virtualización por hardware (Intel VT-x o AMD-V)
habilitada en BIOS/UEFI
•  GB de RAM como mínimo ( GB ideal si se desea correr + nodos simultáneos sin
apagar otros)
•  GB de espacio libre en disco (SSD muy recomendado HDD funcionará pero
más lento)
• Windows / de  bits con permisos de administrador
Paso 2 — Confirmar que la virtualización por hardware está habilitada.
Ver sección E para los comandos exactos.
Paso 3 — Definir el alcance temático del laboratorio.
Ya está definido por el plan de 19 fases (ver tabla de C.2). En esta fase solo lo confirmamos y
lo documentamos como referencia.
Paso 4 — Diseñar el diagrama de arquitectura objetivo.
Usar el diagrama de la sección C como punto de partida; el estudiante debe poder explicarlo
de memoria antes de avanzar.
Paso 5 — Definir convención de nombres.
bdd-nodoNN para nodos de datos, bdd-cliente para la estación de pruebas. Esta convención
se usará en hostname, en el nombre de la VM dentro de VirtualBox, y en las carpetas de
configuración.
Paso 6 — Definir el esquema de direccionamiento IP.
Ya documentado en C.3. Se reserva ahora aunque se configure hasta la Fase 6.
Paso 7 — Definir la estrategia de snapshots.
Cada fase terminada y verificada debe cerrar con un snapshot de VirtualBox nombrado
faseNN-completa en cada VM involucrada. Esto permite retroceder si algo se rompe en una
fase posterior, sin perder el trabajo previo.
Paso 8 — Crear la estructura de carpetas del proyecto en el host.
Ver comandos en la sección E.
Paso 9 — Validar el plan con el checklist de la sección H.

E. Comandos completos
E.1 Verificar virtualización por hardware habilitada (Windows, PowerShell)
Abrir PowerShell (no es necesario ser administrador para esta consulta):
PowerShell
systeminfo
Buscar manualmente en la salida la sección “Requisitos de Hyper-V” (en inglés Hyper-V
Requirements). Debe aparecer:
Text
La virtualización habilitada en firmware: Sí
Si dice “No”, la virtualización está deshabilitada en BIOS/UEFI y debe habilitarse manualmente
reiniciando el equipo y entrando a la configuración de BIOS (la tecla varía por fabricante: Del,
F2, F10, Esc).
E.2 Verificar RAM total y disponible
PowerShell
systeminfo | findstr /C:"Memoria física total" /C:"Memoria físic"
(En equipos en inglés: findstr /C:"Total Physical Memory" )
E.3 Verificar espacio libre en disco
PowerShell
wmic logicaldisk get size,freespace,caption
E.4 Verificar si Hyper-V está activo (posible conflicto con VirtualBox)
PowerShell
bcdedit /enum | findstr hypervisorlaunchtype

Si el resultado es hypervisorlaunchtype Auto , Hyper-V está activo. VirtualBox 7.x moderno
puede coexistir con Hyper-V, pero si en fases posteriores se presentan errores de arranque de
VM ( VT-x is not available ), se puede desactivar así (requiere reinicio):
PowerShell
bcdedit /set hypervisorlaunchtype off
Nota: en este laboratorio normalmente no será necesario desactivar Hyper-V. Se
documenta aquí solo como referencia para la sección de solución de problemas.
E.5 Crear la estructura de carpetas del proyecto (en el host)
PowerShell
mkdir C:\LabBDD
mkdir C:\LabBDD\VMs
mkdir C:\LabBDD\ISOs
mkdir C:\LabBDD\Scripts
mkdir C:\LabBDD\Snapshots-Notas
mkdir C:\LabBDD\Documentacion
Propósito de cada carpeta:
• VMs  aquí vivirán los discos virtuales (vdi) de cada nodo
• ISOs  imagen ISO de Ubuntu Server descargada (se usará en Fase )
• Scripts  scripts de configuración reutilizables que crearemos en fases futuras
• Snapshots-Notas  bitácora en texto de qué representa cada snapshot
• Documentacion  este archivo y los entregables de cada fase
F. Verificación de funcionamiento
Esta fase no instala software, por lo que la “verificación” consiste en confirmar que la
planeación está completa y es correcta:
 systeminfo muestra virtualización habilitada en firmware → Sí
 El host tiene al menos  GB de RAM totales y al menos  GB libres en disco
 La carpeta C:\LabBDD existe con sus  subcarpetas
 El estudiante puede dibujar de memoria el diagrama de arquitectura objetivo (C y C) y
explicar el rol de cada nodo

 El estudiante puede explicar sin ver el documento la diferencia entre fragmentación
horizontal y vertical
G. Problemas comunes y soluciones
| Problema |     | Causa probable | Solución                                    |
| -------- | --- | -------------- | ------------------------------------------- |
|          |     | VT-x/AMD-V     | Reiniciar entrar a BIOS habilitar “Intel  |
systeminfo
|     |     | deshabilitado en  | Virtualization Technology” o “SVM Mode”  |
| --- | --- | ----------------- | ---------------------------------------- |
muestra
| “Virtualización  |     | BIOS/UEFI | (AMD) guardar y reiniciar |
| ---------------- | --- | --------- | -------------------------- |
habilitada en
firmware No”
RAM total reportada  RAM reservada por  Verificar en  Administrador de tareas →
| es menor a la física  |     | gráficos integrados o  |     |
| --------------------- | --- | ---------------------- | --- |
Rendimiento → Memoria  si la diferencia
| instalada |     | módulos defectuosos |     |
| --------- | --- | ------------------- | --- |
es muy grande revisar configuración de
memoria compartida con GPU integrada
Poco espacio libre  Disco con muchos  Liberar espacio antes de avanzar los
en disco archivos/instalaciones  discos virtuales dinámicos crecerán con
|     |     | previas | el uso se necesita margen |
| --- | --- | ------- | -------------------------- |
Hyper-V activo y  Conflicto entre Hyper- Actualizar VirtualBox a la versión x más
futura VM no  V y VirtualBox en  reciente (soporta modo Hyper-V) o
arranca (error  VT-x  versiones antiguas desactivar Hyper-V con  bcdedit  (ver
| is not available |     | )   | E) |
| ---------------- | --- | --- | ---- |
Antivirus bloquea la  Política de seguridad  Solicitar excepción para  C:\LabBDD  y
| creación de  |     | corporativa/educativa  |     |
| ------------ | --- | ---------------------- | --- |
para el ejecutable de VirtualBox en el
| carpetas o  |     | muy restrictiva |     |
| ----------- | --- | --------------- | --- |
antivirus institucional
adaptadores de red
más adelante
H. Checklist de validación
Verifiqué que mi CPU soporta y tiene habilitada la virtualización por hardware.
Confirmé que tengo al menos 16 GB de RAM (idealmente 32 GB).
Confirmé que tengo al menos 120 GB libres en disco.
Creé la estructura de carpetas  C:\LabBDD  con sus 5 subcarpetas.
Puedo explicar la diferencia entre replicación física y lógica.
Puedo explicar la diferencia entre fragmentación horizontal, vertical e híbrida.
Entiendo y puedo reproducir el diagrama de arquitectura objetivo (7 nodos, roles, IPs).
Entiendo por qué se eligió una red Host-Only y no NAT o Bridged.

Tengo claro el plan de crecimiento gradual (de 2 nodos en Fase 3 a 6–7 nodos en Fase 16).
Entiendo la estrategia de snapshots por fase.
I. Preparación para la siguiente fase
La Fase 1: Instalación de VirtualBox requerirá:
• Permisos de administrador en Windows
• Conexión a internet para descargar el instalador desde el sitio oficial de Oracle VirtualBox
• La estructura de carpetas C:\LabBDD ya creada (Paso  de esta fase)
• Haber resuelto cualquier conflicto de virtualización detectado en esta fase (BIOS/UEFI o
Hyper-V)
No se necesita descargar todavía la ISO de Ubuntu Server; eso corresponde a la Fase 4.
Preguntas teóricas para estudiantes
 ¿Qué diferencia existe entre la replicación física y la replicación lógica en un sistema
de bases de datos distribuidas y por qué este laboratorio planea nodos distintos para
cada una?
 ¿Qué significa “transparencia de distribución” y qué tipos de transparencia existen
(fragmentación ubicación replicación concurrencia)?
 ¿Por qué es conveniente separar desde el diseño los nodos dedicados a fragmentación
horizontal de los nodos dedicados a replicación?
 Según el teorema CAP ¿qué compromisos debe enfrentar quien diseña una arquitectura
distribuida como la planeada en este laboratorio?
 ¿Qué ventajas y qué limitaciones tiene usar una sola computadora física para simular un
sistema distribuido de varios nodos comparado con usar varias máquinas físicas reales?
Ejercicios prácticos
 Verificar en su propia computadora si la virtualización por hardware (VT-x/AMD-V) está
habilitada documentando el procedimiento con los comandos de la sección E y el
resultado obtenido (puede incluir capturas de pantalla)
 Elaborar un diagrama propio de la arquitectura objetivo (puede usar papel drawio o
cualquier herramienta) representando los  nodos propuestos sus roles IPs planeadas y la
fase en la que se activa cada uno

 Calcular cuántos nodos podría correr su computadora simultáneamente sin saturar la RAM
usando la fórmula (RAM total - 4 GB reservados para el sistema operativo host) /
RAM asignada por VM  Justificar el resultado con sus propios datos de hardware
Reto adicional para alumnos avanzados
Proponer y justificar técnicamente una arquitectura alternativa que incluya un octavo nodo de
tipo proxy/balanceador (por ejemplo, conceptualmente similar a ProxySQL o MariaDB
MaxScale), indicando en qué fase del plan de 19 fases se debería introducir y qué problema
resolvería que los 7 nodos actuales no resuelven por sí solos. No es necesario implementarlo,
solo justificarlo por escrito.
Criterios de evaluación para el profesor
Criterio Peso Indicador de logro
Verificación de requisitos % El estudiante presenta evidencia
de hardware (capturas/comandos) de que su equipo cumple
los mínimos o documenta correctamente las
limitaciones encontradas
Diagrama de arquitectura % El diagrama incluye todos los nodos roles IPs
y es consistente con el plan de  fases
Comprensión conceptual % Responde correctamente las  preguntas
teóricas con vocabulario técnico adecuado
Justificación de decisiones % Explica con claridad por qué se eligió Host-
de diseño Only Adapter por qué se separan roles
por nodo y por qué se usa una estrategia
de snapshots
Reto avanzado (si aplica) % La propuesta del nodo proxy está
técnicamente justificada y ubicada
coherentemente en el plan de fases

Fase 1 — Instalación de Oracle VirtualBox
Continuación directa de la Fase 0. Se asume que ya existe la estructura de carpetas
C:\LabBDD y que se resolvió cualquier conflicto de virtualización (BIOS/UEFI o Hyper-V)
detectado previamente.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar qué es un hipervisor de Tipo  y diferenciarlo conceptualmente de uno de Tipo 
 Descargar e instalar correctamente Oracle VirtualBox en un host Windows
 Instalar el VirtualBox Extension Pack y entender por qué es un componente separado con
licencia distinta
 Configurar la carpeta predeterminada de máquinas virtuales para que apunte a
C:\LabBDD\VMs en lugar de la ruta por defecto
 Verificar mediante la interfaz gráfica y mediante línea de comandos ( VBoxManage ) que la
instalación quedó funcional
 Reconocer los componentes principales de la interfaz de VirtualBox que se usarán en fases
posteriores (Administrador de VMs Administrador de medios Administrador de redes)
B. Conceptos teóricos necesarios
1. Hipervisor. Software que permite crear y ejecutar máquinas virtuales sobre un hardware
físico (host).
• Tipo  (bare-metal) se ejecuta directamente sobre el hardware sin sistema operativo
anfitrión por debajo (ej VMware ESXi Hyper-V en modo servidor KVM) Suele usarse en
centros de datos
• Tipo  (hosted) se ejecuta como una aplicación dentro de un sistema operativo anfitrión
ya existente (ej VirtualBox VMware Workstation) Es el modelo de este laboratorio
Windows es el host y VirtualBox corre como un programa más dentro de él
2. VirtualBox como producto. Es un hipervisor de Tipo 2 de propósito general, mantenido por
Oracle, que permite crear máquinas virtuales x86_64 con soporte para Windows, Linux, macOS
(Intel) y Solaris como sistemas invitados.

3. Paquete base vs. Extension Pack. VirtualBox se distribuye en dos partes con
licencias distintas:
• El paquete base es software libre bajo licencia GNU GPL v
• El Extension Pack es un componente adicional de licencia propietaria (gratuita para uso
personal/educativo pero no de código abierto) que agrega soporte para dispositivos USB
/ Remote Desktop Protocol (RDP) cifrado de disco y arranque PXE para tarjetas de
red Intel En este laboratorio se instalará porque facilitará el uso de USB y opcionalmente
acceso remoto a las VMs en fases posteriores
4. ¿Por qué versión 7.2.x? La rama 7.2 es, a la fecha de esta guía, la rama en mantenimiento
activo de VirtualBox; las ramas 7.1, 7.0 y 6.1 ya no reciben soporte. Se recomienda siempre
instalar la última versión estable de la rama activa, descargada únicamente desde el
sitio oficial.
5. VBoxManage . Herramienta de línea de comandos incluida con VirtualBox que permite hacer,
mediante scripts, todo lo que la interfaz gráfica permite hacer manualmente (crear VMs,
discos, snapshots, redes, etc.). Se usará intensivamente a partir de la Fase 3 para automatizar
la creación de nodos.
C. Procedimiento paso a paso
Paso 1 — Descargar el instalador desde el sitio oficial.
Ir a https://www.virtualbox.org/wiki/Downloads (nunca desde portales de terceros tipo
Softonic/Uptodown, para evitar instaladores modificados). Descargar el paquete para
“Windows hosts” de la rama estable más reciente (7.2.x al momento de escribir esta guía).
Paso 2 — Descargar el Extension Pack correspondiente.
En la misma página de descargas, descargar “VirtualBox Extension Pack”. Es un único archivo
.vbox-extpack válido para todas las plataformas; debe coincidir en número de versión
mayor.menor con el instalador base (ej. ambos 7.2.x).
Paso 3 — Ejecutar el instalador base con permisos de administrador.
Doble clic en el .exe descargado → “Sí” en el control de cuentas de usuario (UAC). Durante el
asistente:
• Dejar las características marcadas por defecto (VirtualBox USB Support VirtualBox
Networking VirtualBox Python x/x Support si aparece)
• Cuando pregunte por la ruta de instalación del programa (no de las VMs) se puede dejar la
ruta por defecto ( C:\Program Files\Oracle\VirtualBox\ ) esto es distinto de dónde
vivirán los discos de las VMs que se configura en el Paso 

• Aceptar la advertencia de “se perderá temporalmente la conectividad de red” (VirtualBox
instala adaptadores de red virtuales puede desconectar brevemente el Wi-Fi/Ethernet del
host durante la instalación)
• Finalizar e iniciar VirtualBox al terminar
Paso 4 — Instalar el Extension Pack desde la interfaz gráfica.
Con VirtualBox abierto: Archivo → Herramientas → Administrador de medios no es la ruta
correcta para esto; en su lugar ir a Archivo → Preferencias → Extensiones → ícono "+"
(Agregar paquete) , seleccionar el archivo .vbox-extpack descargado en el Paso 2, dar clic
en “Instalar” y aceptar la licencia (PUEL — Personal Use and Evaluation License).
Paso 5 — Verificar la versión instalada.
En la interfaz: Ayuda → Acerca de VirtualBox . Debe coincidir la versión del programa con la
del Extension Pack (ver comandos en sección D para verificación por línea de comandos).
Paso 6 — Redirigir la carpeta predeterminada de máquinas virtuales.
Por defecto, VirtualBox guarda discos y configuraciones en C:\Users\<usuario>\VirtualBox
VMs\ . Para mantener todo el laboratorio organizado dentro de C:\LabBDD , cambiar esta ruta:
Archivo → Preferencias → General → Carpeta predeterminada de máquinas → cambiar a
C:\LabBDD\VMs .
Importante: este cambio solo afecta a las VMs que se creen después de modificarlo; no
mueve nada existente (en este punto no debería haber ninguna VM creada todavía).
Paso 7 — Revisar el Administrador de redes (sin crear nada todavía).
Herramientas → Red (o Archivo → Herramientas → Administrador de redes de host ).
Simplemente confirmar que la pestaña “Adaptadores solo-anfitrión” existe y está vacía. La
creación del adaptador vboxnet0 con la IP 192.168.56.1 planeada en la Fase 0 se hará
formalmente en la Fase 2, no aquí.
Paso 8 — Cerrar snapshot conceptual de la fase.
Como todavía no existen VMs, no hay nada que snapshotear en VirtualBox en este punto. En
su lugar, anotar en C:\LabBDD\Snapshots-Notas\fase01-notas.txt la versión exacta
instalada (base + Extension Pack) y la fecha, para trazabilidad.

D. Comandos
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
Debe mostrar el paquete Oracle VM VirtualBox Extension Pack con número de versión y
revisión ( r ) idéntico al del paso D.1.

D.4 Confirmar que aún no existen máquinas virtuales (esperado en
esta fase)
PowerShell
VBoxManage list vms
Salida esperada: vacío (todavía no se ha creado ningún nodo; eso corresponde a la Fase 3).
D.5 Confirmar la carpeta predeterminada configurada en el Paso 6
PowerShell
VBoxManage list systemproperties | findstr /C:"Default machine folder"
Debe mostrar C:\LabBDD\VMs .
E. Verificación de funcionamiento
 VBoxManage --version se ejecuta sin errores y reporta una versión de la rama x (o la
rama estable vigente al momento de instalar)
 VBoxManage list extpacks muestra el Extension Pack instalado con número de versión
coincidente con el del paquete base
 La interfaz gráfica de VirtualBox abre sin mensajes de error ni advertencias de
drivers faltantes
 Archivo → Preferencias → General → Carpeta predeterminada de máquinas muestra
C:\LabBDD\VMs 
 VBoxManage list vms regresa vacío (correcto para esta fase todavía no se crean nodos)
 Existe el archivo C:\LabBDD\Snapshots-Notas\fase01-notas.txt con la versión instalada
y la fecha

F. Problemas comunes y soluciones
Problema Causa probable Solución
El instalador Antivirus o políticas Agregar excepción temporal para el
falla con error de grupo bloquean la instalador en el antivirus institucional
de “Python instalación de drivers de reintentar instalación como administrador
Core” o red virtuales
“Network
Interfaces” a
mitad de
instalación
Mensaje VT-x Hyper-V activo entrando en Revisar de nuevo bcdedit /enum |
is not conflicto o virtualización findstr hypervisorlaunchtype (ver
available al deshabilitada en BIOS (no Fase  sección E) actualizar a la
intentar usar resuelto desde la Fase ) última versión x que tiene mejor
VirtualBox coexistencia con Hyper-V
después de
instalarlo
El Extension Se descargó una versión del Verificar ambos números de versión en
Pack no aparece Extension Pack que virtualbox.org/wiki/Downloads 
o aparece como no coincide con la deben coincidir en X.Y (ej ambos x)
“no compatible” versión mayormenor del
paquete base
La red se El adaptador de red físico Esperar – minutos o
desconecta tarda en re-negociar tras la deshabilitar/habilitar el adaptador
brevemente instalación de los drivers de de red físico desde el Administrador
durante la VirtualBox de dispositivos
instalación y no
vuelve sola
VBoxManage no No se agregó al PATH Cerrar todas las ventanas de
se reconoce (paso D) o no se reinició PowerShell/CMD abiertas y abrir una
como comando la terminal después nueva o usar la ruta completa como
de agregarlo en D
El instalador Es normal cuando se Reiniciar y volver a abrir VirtualBox
pide reiniciar instalan por primera vez los para continuar
Windows drivers de red/USB de
VirtualBox
G. Checklist de validación
Descargué VirtualBox únicamente desde virtualbox.org , rama estable vigente (no de
portales de terceros).

Descargué el Extension Pack con número de versión X.Y coincidente con el paquete
base.
Instalé VirtualBox con permisos de administrador y reinicié si fue solicitado.
Instalé el Extension Pack desde Preferencias → Extensiones y acepté la licencia PUEL.
VBoxManage --version y VBoxManage list extpacks se ejecutan correctamente desde
PowerShell.
Cambié la carpeta predeterminada de máquinas a C:\LabBDD\VMs .
Confirmé que VBoxManage list vms está vacío (todavía no toca crear nodos).
Documenté la versión instalada en C:\LabBDD\Snapshots-Notas\fase01-notas.txt .
Puedo explicar la diferencia entre un hipervisor Tipo 1 y Tipo 2, y por qué VirtualBox es
Tipo 2.
Puedo explicar por qué el Extension Pack es un componente separado, con licencia
distinta al paquete base.
H. Preparación para la siguiente fase
La Fase 2: Configuración de la red Host-Only requerirá:
• VirtualBox y su Extension Pack ya instalados y verificados (esta fase)
• Comprender el plan de direccionamiento IP definido en la Fase  sección C
( 192.168.56.0/24 )
• Tener claro por qué se eligió Host-Only sobre NAT o Bridged (mencionado en Fase  se
justificará a fondo en Fase )
Todavía no se crea ninguna máquina virtual; eso corresponde a la Fase 3, una vez configurada
la red.

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

Fase 4 — Descarga y Verificación de
la Imagen ISO de Ubuntu Server LTS
Continuación del Laboratorio de Bases de Datos Distribuidas. En esta fase no se crea
ninguna máquina virtual todavía: solo se obtiene, verifica y almacena la imagen ISO que se
usará en la Fase 5 para instalar el sistema operativo en los nodos.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar qué es una imagen ISO y por qué se usa como medio de instalación para sistemas
operativos en máquinas virtuales
 Distinguir entre las versiones LTS (Long Term Support) y las versiones interinas de Ubuntu
y justificar por qué este laboratorio usa exclusivamente una versión LTS
 Descargar correctamente la imagen ISO de Ubuntu Server desde una fuente oficial
 Verificar la integridad de un archivo descargado mediante un hash criptográfico (SHA)
y entender por qué este paso no es opcional en un entorno de laboratorio serio
 Ubicar el archivo descargado en la estructura de carpetas definida en la Fase 
( C:\LabBDD\ISOs )
B. Conceptos teóricos necesarios
1. Imagen ISO. Un archivo .iso es una copia exacta (sector por sector) del contenido de un
disco óptico. VirtualBox puede “montar” este archivo como si fuera un DVD físico insertado en
la unidad óptica virtual de una VM, permitiendo arrancar el instalador del sistema operativo sin
necesidad de quemar un disco real.
2. Ubuntu Server vs. Ubuntu Desktop. Para este laboratorio se usa Ubuntu Server, no Ubuntu
Desktop. Ubuntu Server no incluye entorno gráfico (GNOME, etc.), lo cual reduce el consumo
de RAM y disco — un factor crítico porque el plan final contempla correr varios nodos
simultáneamente sobre el mismo host. Toda la administración de los nodos se hará por línea
de comandos (SSH, terminal de VirtualBox).
3. Versiones LTS vs. interinas. Canonical (la empresa detrás de Ubuntu) publica una versión
nueva cada seis meses, pero solo las versiones LTS (publicadas cada dos años, en abril de
años pares) reciben soporte extendido — típicamente 5 años de actualizaciones de seguridad,
1

ampliables con Ubuntu Pro. Las versiones interinas (por ejemplo, 25.10) reciben soporte de
solo 9 meses. Para un laboratorio académico que puede extenderse varios meses, siempre se
debe usar una versión LTS, nunca una interina.
A la fecha de esta fase existen dos LTS disponibles:
• Ubuntu Server  LTS “Noble Numbat” (en su punto de actualización ): es la
opción recomendada para este laboratorio Lleva más de dos años en circulación tiene
soporte hasta  y prácticamente toda la documentación de MariaDB tutoriales y foros
de la comunidad está probada contra esta versión Para un laboratorio enfocado en bases
de datos distribuidas (y no en probar las características más nuevas de Linux) la
estabilidad y la documentación disponible pesan más que tener la versión más reciente
• Ubuntu Server  LTS “Resolute Raccoon” es la LTS más nueva publicada apenas en
abril de este año Es una opción válida si el estudiante prefiere trabajar con la versión más
reciente pero al ser tan reciente puede tener más fricciones (paquetes de MariaDB recién
adaptados menos tutoriales de terceros menos tiempo de maduración del primer punto
de actualización)
Decisión para este laboratorio: se usará Ubuntu Server 24.04.x LTS. Si el estudiante desea
usar 26.04 LTS en su lugar, el procedimiento de esta fase es idéntico; solo cambia el nombre
del archivo descargado.
4. Verificación de integridad (checksum). Un archivo de varios cientos de megabytes puede
corromperse durante la descarga (conexión interrumpida, proxy institucional que modifica el
tráfico, disco con sectores defectuosos) sin que el sistema operativo lo reporte como error.
Para detectar esto, Canonical publica junto con cada ISO un archivo SHA256SUMS que contiene
el hash criptográfico SHA-256 esperado de cada imagen. Si el hash calculado sobre el archivo
descargado no coincide exactamente con el publicado, el archivo está corrupto o fue
alterado y no debe usarse para instalar ningún nodo.
5. Por qué importa especialmente en este laboratorio. Como la imagen ISO descargada en
esta fase se reutilizará para instalar los 6–7 nodos del plan completo (Fases 5 en adelante), un
archivo corrupto introduciría errores intermitentes y difíciles de diagnosticar más adelante
(fallas de instalación de paquetes, comportamiento errático del kernel) que podrían
confundirse con problemas de replicación o de red. Verificar una sola vez aquí evita ese riesgo
en las siete instalaciones futuras.
C. Procedimiento paso a paso
Paso 1 — Confirmar que la carpeta de destino existe.
La carpeta C:\LabBDD\ISOs debió crearse en la Fase 0 (Paso 8). Si no existe, créala antes de
continuar (ver sección D).
2

Paso 2 — Verificar espacio libre en disco.
La ISO de Ubuntu Server pesa aproximadamente 2–3 GB. Confirma que tienes al menos 10 GB
libres antes de iniciar la descarga, considerando que más adelante se necesitará espacio
adicional para los discos virtuales.
Paso 3 — Ir al sitio oficial de descarga.
Navega a https://ubuntu.com/download/server (o directamente a
https://releases.ubuntu.com/24.04/ para acceder al listado de archivos del release). No
descargues la ISO desde sitios de terceros, blogs o “mirrors” no oficiales — el riesgo de
obtener una imagen modificada es real y el paso de verificación de checksum pierde sentido si
la fuente ya no es confiable.
Paso 4 — Descargar la imagen ISO “live server”.
Selecciona la descarga directa (no torrent, salvo que tu conexión sea muy lenta o inestable, en
cuyo caso el torrent es una alternativa válida y oficial). El archivo tendrá un nombre similar a:
Text
ubuntu-24.04.4-live-server-amd64.iso
Paso 5 — Descargar el archivo de checksums oficial.
En la misma página de releases, descarga también el archivo SHA256SUMS (texto plano con los
hashes de todos los archivos de ese release). Guárdalo en la misma carpeta temporal donde
quedó la ISO.
Paso 6 — Calcular el hash SHA-256 del archivo descargado.
Usa PowerShell para calcular el hash real del archivo que descargaste (ver comandos en
sección D).
Paso 7 — Comparar el hash calculado contra el publicado.
Abre SHA256SUMS con un editor de texto y localiza la línea correspondiente al nombre exacto
de tu archivo ISO. Compara el valor hexadecimal carácter por carácter (o usa el comando de
comparación automática de la sección D). Deben coincidir exactamente.
Paso 8 — Mover la ISO verificada a la carpeta del proyecto.
Una vez confirmada la integridad, mueve (no copies, para no dejar duplicados) el archivo
.iso a C:\LabBDD\ISOs .
Paso 9 — Documentar la descarga.
Anota en C:\LabBDD\Documentacion (o en tu bitácora de la Fase 0) la versión exacta
descargada (ej. 24.04.4 ), la fecha de descarga y el resultado de la verificación de hash. Esto
3

será útil si en fases posteriores necesitas reinstalar un nodo y quieres asegurarte de usar la
misma versión que los demás.
Paso 10 — Validar con el checklist de la sección G.
D. Comandos completos
D.1 Crear la carpeta de destino (si no existe todavía)
PowerShell
mkdir C:\LabBDD\ISOs -Force
D.2 Verificar espacio libre en disco antes de descargar
PowerShell
wmic logicaldisk get size,freespace,caption
D.3 Calcular el hash SHA-256 del archivo ISO descargado
Ajusta la ruta al lugar donde el navegador guardó el archivo (normalmente Descargas ):
PowerShell
Get-FileHash "$env:USERPROFILE\Downloads\ubuntu-24.04.4-live-server-amd64.iso"
-Algorithm SHA256
El resultado se ve así (el valor real será distinto):
Text
Algorithm Hash
Path
--------- ----
----
SHA256 A1B2C3D4E5F6...
C:\Users\...\ubuntu-24.04.4-live-server-amd64.iso
4

D.4 Comparar automáticamente el hash contra el archivo SHA256SUMS
Si descargaste también SHA256SUMS en la misma carpeta, este script evita la comparación
manual:
PowerShell
$archivoIso = "ubuntu-24.04.4-live-server-amd64.iso"
$rutaIso = "$env:USERPROFILE\Downloads\$archivoIso"
$rutaSums = "$env:USERPROFILE\Downloads\SHA256SUMS"
$hashCalculado = (Get-FileHash $rutaIso -Algorithm SHA256).Hash.ToLower()
$lineaEsperada = Select-String -Path $rutaSums -Pattern $archivoIso
$hashEsperado = ($lineaEsperada.Line -split "\s+")[0].ToLower()
if ($hashCalculado -eq $hashEsperado) {
Write-Host "OK: el hash coincide. La ISO esta integra." -
ForegroundColor Green
} else {
Write-Host "ERROR: el hash NO coincide. Vuelve a descargar el archivo." -
ForegroundColor Red
}
D.5 Mover la ISO verificada a la carpeta del proyecto
PowerShell
Move-Item "$env:USERPROFILE\Downloads\ubuntu-24.04.4-live-server-
amd64.iso" "C:\LabBDD\ISOs\"
D.6 Confirmar que el archivo quedó en su lugar y con el tamaño esperado
PowerShell
Get-Item "C:\LabBDD\ISOs\ubuntu-24.04.4-live-server-amd64.iso" | Select-Object
Name, Length, LastWriteTime
E. Verificación de funcionamiento
Esta fase se considera completa cuando se cumple lo siguiente:
 El archivo .iso existe físicamente en C:\LabBDD\ISOs (verificado con Get-Item 
sección D)
 El tamaño del archivo es coherente con una imagen “live server” de Ubuntu
(aproximadamente – GB un archivo de pocos KB o MB indica una descarga fallida
o incompleta)
5

 El hash SHA- calculado sobre el archivo coincide exactamente con el publicado en
| SHA256SUMS |  para esa misma versión |     |     |     |
| ---------- | ------------------------ | --- | --- | --- |
 El estudiante puede explicar sin ver este documento qué problema resuelve la verificación
de checksum y qué pasaría si se omitiera este paso
 La versión descargada (x LTS o x LTS) quedó documentada por escrito junto
con la fecha de descarga
F. Problemas comunes y soluciones
| Problema | Causa probable | Solución |     |     |
| -------- | -------------- | -------- | --- | --- |
La descarga se  Conexión inestable  Usar la opción de descarga por
detiene o falla  proxy institucional que  BitTorrent disponible en la misma página
repetidamente corta descargas largas oficial que reanuda automáticamente
partes incompletas
El hash  Descarga corrupta o se  Eliminar el archivo y volver a
| calculado no  | descargó el archivo de  | descargarlo desde  |     |     |
| ------------- | ----------------------- | ------------------ | --- | --- |
coincide con el  una fuente no oficial releases.ubuntu.com  nunca usar una
| publicado         |                          | ISO cuyo hash no coincida |                   |     |
| ----------------- | ------------------------ | ------------------------- | ----------------- | --- |
| El antivirus      | Falsos positivos         | Solicitar excepción para  |                   |     |
| marca el archivo  | frecuentes con archivos  |                           |  en el antivirus  |     |
C:\LabBDD\ISOs
 como  de instalación de Linux  institucional (mismo procedimiento que
.iso
sospechoso o lo  en software  se documentó en la Fase  para la
| bloquea | corporativo/educativo | carpeta del proyecto) |     |     |
| ------- | --------------------- | --------------------- | --- | --- |
No queda claro  El archivo  SHA256SUMS   Buscar específicamente la línea que
qué línea de  lista los hashes de todas  contiene el nombre exacto del archivo
|            |                            | descargado (ej  |                   | )  |
| ---------- | -------------------------- | ---------------- | ----------------- | --- |
| SHA256SUMS | las variantes del release  |                  | live-server-amd64 |     |
corresponde al  (desktop server  usando  Select-String  como en el
| archivo  | distintas arquitecturas) |     |     |     |
| -------- | ------------------------ | --- | --- | --- |
comando de la sección D
descargado
Poco espacio en  La carpeta  C:\LabBDD   Liberar espacio o si es necesario
disco al intentar  quedó en una unidad con  mover toda la carpeta  C:\LabBDD  a una
mover el archivo
|     | poco espacio libre | unidad con más espacio antes de  |     |     |
| --- | ------------------ | -------------------------------- | --- | --- |
continuar a fases posteriores
Se descargó por  Confusión en el sitio de  Verificar que el nombre del archivo y la
error una  descarga entre releases  página de origen indiquen
versión interina  LTS e interinos explícitamente “LTS” eliminar el archivo
| (no LTS) |     | interino y descargar la versión correcta |     |     |
| -------- | --- | ---------------------------------------- | --- | --- |
6

G. Checklist de validación
| Confirmé que existe la carpeta  |     | C:\LabBDD\ISOs | .   |
| ------------------------------- | --- | -------------- | --- |
Verifiqué que tengo al menos 10 GB libres en disco antes de descargar.
Descargué la imagen ISO de Ubuntu Server LTS (24.04.x o 26.04.x) desde una fuente
| oficial (  |  o                  |     | ).  |
| ---------- | ------------------- | --- | --- |
| ubuntu.com | releases.ubuntu.com |     |     |
Descargué también el archivo  SHA256SUMS  correspondiente al mismo release.
Calculé el hash SHA-256 de mi archivo descargado con  Get-FileHash .
Comparé el hash calculado contra el publicado y coinciden exactamente.
| Moví la ISO verificada a  | C:\LabBDD\ISOs | .   |     |
| ------------------------- | -------------- | --- | --- |
Confirmé el tamaño y la ubicación final del archivo.
Documenté la versión exacta y la fecha de descarga.
Puedo explicar qué es una imagen ISO y por qué se verifica su checksum antes de usarla.
7

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

Fase 6 — Configuración de IP Estática
dentro de los Nodos (Netplan)
Continuación directa de la Fase 5. Ambas VMs ( bdd-nodo01 , bdd-nodo02 ) tienen Ubuntu
Server 24.04 LTS instalado, OpenSSH activo, y un snapshot fase05-completa . En esta fase
se asigna, dentro de cada sistema operativo invitado, la dirección IP estática reservada
desde la Fase 0 (sección C.3), dejando los nodos accesibles por SSH desde el host por
primera vez.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar qué es Netplan y cómo se relaciona con systemd-networkd en Ubuntu Server (a
diferencia de NetworkManager usado en Ubuntu Desktop)
 Identificar el archivo de configuración de red generado automáticamente por el instalador
( /etc/netplan/50-cloud-init.yaml ) y modificarlo de forma segura
 Asignar una dirección IPv estática a la interfaz enp0s3 de cada nodo conforme al plan
de direccionamiento de la Fase 
 Aplicar los cambios de red sin reiniciar la VM usando netplan apply  y entender el
mecanismo de seguridad de netplan try 
 Justificar por qué no se configura puerta de enlace (gateway) ni servidores DNS en esta
fase dado el diseño de red Host-Only definido en la Fase 
 Configurar resolución de nombres básica vía /etc/hosts en cada nodo (y opcionalmente
en el host Windows) para poder referirse a los nodos por nombre en lugar de por IP en
fases futuras
 Verificar conectividad bidireccional host↔VM y VM↔VM y establecer la primera
conexión SSH real desde el host Windows
 Cerrar la fase con un snapshot fase06-completa en ambas VMs
B. Conceptos teóricos necesarios
1. Netplan. Es la herramienta de configuración de red por defecto en Ubuntu desde la versión
18.04 (tanto Desktop como Server). No es un servicio en sí mismo: es una capa de abstracción
que traduce archivos de configuración en formato YAML (ubicados en /etc/netplan/ ) hacia
el backend real que gestiona la red — en Ubuntu Server ese backend es systemd-networkd ;
1

en Ubuntu Desktop suele ser NetworkManager. Esta diferencia explica por qué los tutoriales
orientados a escritorio (que hablan de editar conexiones desde una interfaz gráfica) no
aplican aquí.
2. El archivo generado por Subiquity. Durante la instalación (Fase 5), como la pantalla de red
no tenía nada que configurar (sin DHCP disponible), Subiquity de todos modos generó un
archivo de Netplan por defecto, normalmente llamado /etc/netplan/50-cloud-init.yaml ,
con la interfaz configurada en modo dhcp4: true . Este archivo fue escrito por cloud-init
durante el primer arranque ( curtin / cloud-init son parte del proceso de instalación de
Subiquity). A partir de Ubuntu 20.04, el instalador deja además un archivo en
/etc/cloud/cloud.cfg.d/ que deshabilita la gestión de red por cloud-init en arranques
posteriores, por lo que es seguro editar manualmente 50-cloud-init.yaml sin que cloud-init
lo sobrescriba en el siguiente reinicio. Aun así, en esta guía se aplican los cambios con
netplan apply (sin reiniciar), lo cual permite verificar el comportamiento sin depender de ese
detalle.
3. Por qué no se configura gateway ni DNS en esta fase. El adaptador Host-Only (Fase 2)
conecta exclusivamente al host y a las demás VMs del laboratorio; no existe ningún router en
ese segmento que pueda actuar como puerta de enlace hacia internet. Definir una gateway4
o servidores nameservers en este punto no tendría ningún destino válido y solo generaría
confusión. Esto es consistente con lo ya advertido en la Fase 5 (sección B.5): los nodos
seguirán sin acceso a internet después de esta fase. Si una fase posterior requiere que los
nodos instalen paquetes (por ejemplo, MariaDB), se resolverá entonces — típicamente
agregando un segundo adaptador de red en modo NAT únicamente para salida a internet,
dejando el adaptador Host-Only intacto para la comunicación interna del clúster. Por ahora, un
solo adaptador, sin gateway, es correcto.
4. Formato YAML de Netplan (sintaxis mínima necesaria). Una declaración de IP estática
para una interfaz Ethernet sigue esta estructura:
YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: no
addresses:
- 192.168.56.101/24
/24 es la notación CIDR equivalente a la máscara 255.255.255.0 definida en la Fase 0 y
aplicada al adaptador Host-Only en la Fase 2. La indentación en YAML es significativa
(espacios, nunca tabuladores); un error de indentación es la causa más común de fallas en
2

esta fase.
5. netplan apply vs. netplan try . netplan apply aplica la configuración inmediatamente
y de forma permanente. netplan try la aplica de forma temporal (revierte automáticamente
a los 120 segundos si no se confirma con Enter), lo cual es más seguro cuando se edita la red
de una máquina a la que solo se tiene acceso por esa misma red — no es el caso aquí, porque
se trabaja desde la consola gráfica de VirtualBox, pero es una buena práctica que conviene
conocer para sistemas administrados exclusivamente por SSH.
6. Permisos del archivo de Netplan. Netplan exige que sus archivos YAML tengan permisos
restrictivos ( 600 , solo lectura/escritura para root ) porque pueden contener credenciales de
red (por ejemplo, contraseñas de Wi-Fi en otros contextos). Si el archivo se editó con permisos
más abiertos, Netplan emite una advertencia y puede negarse a aplicarlo en versiones
recientes.
7. /etc/hosts como resolución de nombres mínima. Este laboratorio no contempla levantar
un servidor DNS propio. Para poder referirse a los nodos por nombre ( ssh bddadmin@bdd-
nodo02 en vez de ssh bddadmin@192.168.56.102 ) — algo que facilitará mucho la
configuración de replicación en fases futuras — se agrega una entrada estática por nodo en el
archivo /etc/hosts de cada VM. Cada vez que se incorpore un nodo nuevo al laboratorio
(Fases 11, 13, 14…), se deberá añadir su entrada correspondiente en /etc/hosts de todos los
nodos existentes; por ahora solo se agregan las entradas de bdd-nodo01 y bdd-nodo02 .
C. Procedimiento paso a paso
Paso 1 — Encender bdd-nodo01 desde VirtualBox.
Debe arrancar directo al prompt de login (sin instalador), tal como quedó al cierre de la Fase 5.
Paso 2 — Iniciar sesión con el usuario bddadmin .
Usar la contraseña definida durante la instalación.
Paso 3 — Identificar el archivo de Netplan existente.
Ver comando en sección D.1. Confirmar el nombre exacto del archivo y de la interfaz de red
detectada por el kernel.
Paso 4 — Hacer una copia de respaldo del archivo original antes de editarlo.
Ver comando en sección D.2. Buena práctica antes de modificar cualquier archivo de
configuración crítico.
Paso 5 — Editar el archivo de Netplan con la IP estática correspondiente a bdd-nodo01 .
192.168.56.101/24 , sin gateway4 ni nameservers (ver justificación en B.3). Ver contenido
completo en sección D.3.
3

Paso 6 — Corregir permisos del archivo, si es necesario.
Ver comando en sección D.4.
Paso 7 — Aplicar la configuración.
Ver comando en sección D.5. No requiere reiniciar la VM.
Paso 8 — Verificar la IP asignada dentro de la VM.
Ver comando en sección D.6.
Paso 9 — Agregar las entradas de /etc/hosts dentro de bdd-nodo01 .
Ver contenido en sección D.7.
Paso 10 — Repetir los Pasos 1 a 9 para bdd-nodo02 , usando la IP 192.168.56.102/24 y el
mismo contenido de /etc/hosts (las entradas son idénticas en ambos nodos).
Paso 11 — Verificar conectividad desde el host Windows hacia ambos nodos.
Ver comandos en sección D.8.
Paso 12 — Verificar conectividad entre los propios nodos (VM↔VM).
Desde bdd-nodo01 , hacer ping a bdd-nodo02 y viceversa (sección D.9).
Paso 13 — Establecer la primera conexión SSH real desde el host.
Ver comando en sección D.10.
Paso 14 (opcional, recomendado) — Agregar entradas equivalentes en el archivo hosts de
Windows.
Permite usar ssh bddadmin@bdd-nodo01 desde PowerShell sin recordar la IP. Ver sección D.11.
Paso 15 — Apagar ambas VMs de forma ordenada y tomar el snapshot de cierre de fase.
Ver secciones D.12 y D.13.
Paso 16 — Validar con el checklist de la sección G.
D. Comandos completos
Los comandos marcados como “dentro de la VM” se ejecutan en la consola de Ubuntu
Server abierta por VirtualBox (login con bddadmin ). Los demás se ejecutan en PowerShell,
en el host Windows.
4

D.1 Identificar el archivo de Netplan y el nombre de la interfaz (dentro de
la VM)
Bash
ls /etc/netplan/
cat /etc/netplan/50-cloud-init.yaml
ip a
La interfaz relevante (la única, además de lo ) debería llamarse enp0s3 . Si el nombre
reportado por ip a es distinto (por ejemplo ens3 en algunas combinaciones de
chipset/versión de VirtualBox), usar ese nombre exacto en todos los pasos siguientes.
D.2 Respaldar el archivo original (dentro de la VM)
Bash
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-
cloud-init.yaml.bak
D.3 Editar el archivo de Netplan (dentro de la VM)
Bash
sudo nano /etc/netplan/50-cloud-init.yaml
Contenido completo para bdd-nodo01 (reemplazar todo el contenido del archivo):
YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: no
addresses:
- 192.168.56.101/24
Para bdd-nodo02 , el único cambio es la dirección:
5

YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: no
addresses:
- 192.168.56.102/24
Guardar con Ctrl+O , Enter , y salir con Ctrl+X .
D.4 Corregir permisos del archivo (dentro de la VM)
Bash
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
D.5 Aplicar la configuración (dentro de la VM)
Bash
sudo netplan apply
Si se prefiere verificar antes de confirmar de forma permanente (no estrictamente necesario
aquí, ya que se trabaja desde la consola local de VirtualBox y no por SSH):
Bash
sudo netplan try
D.6 Verificar la IP asignada (dentro de la VM)
Bash
ip a show enp0s3
Debe mostrar inet 192.168.56.101/24 (o .102 en el segundo nodo) en estado UP .
6

D.7 Agregar entradas en /etc/hosts (dentro de cada VM, contenido
idéntico en ambas)
Bash
sudo nano /etc/hosts
Agregar al final del archivo (sin eliminar las líneas existentes de 127.0.0.1 y ::1 ):
Text
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
Nota: a medida que se incorporen nuevos nodos en fases futuras (03, 04, 05, 06, cliente),
estas líneas deberán ampliarse con las IPs correspondientes en todos los nodos existentes,
conforme a la tabla de direccionamiento de la Fase 0 (sección C.3).
D.8 Verificar conectividad desde el host Windows (PowerShell)
PowerShell
ping 192.168.56.101
ping 192.168.56.102
Ambos deben responder sin pérdida de paquetes.
D.9 Verificar conectividad entre nodos (dentro de bdd-nodo01 )
Bash
ping -c 4 bdd-nodo02
Debe resolver el nombre vía /etc/hosts y recibir respuesta de 192.168.56.102 .
7

D.10 Primera conexión SSH real desde el host (PowerShell)
PowerShell
ssh bddadmin@192.168.56.101
Aceptar la huella digital (fingerprint) del host la primera vez ( yes ), e introducir la contraseña
definida en la Fase 5. Repetir para 192.168.56.102 . Para salir de la sesión SSH:
Bash
exit
D.11 (Opcional) Agregar entradas en el archivo hosts de Windows
Editar como administrador (PowerShell elevado):
PowerShell
notepad C:\Windows\System32\drivers\etc\hosts
Agregar al final:
Text
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
Guardar. A partir de aquí, ssh bddadmin@bdd-nodo01 funciona igual que usar la IP
directamente.
D.12 Apagar ambas VMs de forma ordenada
Dentro de cada VM (vía consola o la sesión SSH recién verificada):
Bash
sudo poweroff
8

D.13 Tomar el snapshot de cierre de fase (PowerShell, ambas
VMs apagadas)
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase06-completa" --description "IP
estatica 192.168.56.101 asignada via Netplan, SSH verificado desde el host"
VBoxManage snapshot "bdd-nodo02" take "fase06-completa" --description "IP
estatica 192.168.56.102 asignada via Netplan, SSH verificado desde el host"
Confirmar:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
E. Verificación de funcionamiento
 ip a show enp0s3 dentro de cada VM muestra la IP estática correcta ( .101 / .102 ) sin
depender de DHCP
 La configuración sobrevive a netplan apply sin errores ni advertencias de permisos
 ping 192.168.56.101 y ping 192.168.56.102 responden correctamente desde el host
Windows
 Desde bdd-nodo01  ping bdd-nodo02 resuelve el nombre vía /etc/hosts y recibe
respuesta
 ssh bddadmin@192.168.56.101 (y .102 ) conecta exitosamente desde el host solicitando
únicamente la contraseña (sin errores de red o de host inalcanzable)
 Ambos snapshots fase06-completa existen y están asociados al estado correcto
(apagadas con IP ya configurada)
 El estudiante puede explicar por qué esta fase no configuró gateway ni DNS y qué fase
futura resolverá el acceso a internet de los nodos si llega a ser necesario
9

F. Problemas comunes y soluciones
| Problema           | Causa probable | Solución           |     |
| ------------------ | -------------- | ------------------ | --- |
| netplan apply      |   Indentación  | Revisar que        |     |
| devuelve un        | incorrecta     | cada nivel use     |     |
| error de sintaxis  | (mezcla de     | exactamente       |     |
| YAML               | tabuladores y  | espacios           |     |
|                    | espacios o    | adicionales        |     |
|                    | niveles        | respecto al nivel  |     |
|                    | desalineados)  | superior nunca    |     |
usar
tabuladores
comparar contra
el ejemplo
exacto de la
sección D
| Advertencia       | El archivo quedó  | Ejecutar  sudo       |     |
| ----------------- | ----------------- | -------------------- | --- |
| “Permissions for  | con permisos      | chmod 600            |     |
| … are too open”   | distintos a       | 600   /etc/netplan/5 |     |
tras editarlo
0-cloud-

init.yaml
(sección D) y
volver a aplicar
| ip a  sigue   | Nombre de      | Confirmar el     |     |
| ------------- | -------------- | ---------------- | --- |
| mostrando la  | interfaz mal   | nombre real con  |     |
|               | escrito en el  |  (sección        |     |
interfaz sin IP  ip a
YAML (por
| después de    |                   | D) antes de     |     |
| ------------- | ----------------- | ----------------- | --- |
|               | ejemplo           |   editar y       |     |
| netplan apply |                   | enp0s3            |     |
|               | cuando el kernel  | corregirlo en el  |     |
|               | detectó           | ) archivo YAML    |     |
ens3
| El host no     | El Adaptador   | Verificar con   |     |
| -------------- | --------------- | --------------- | --- |
| puede hacer    | de la VM no     | VBoxManage      |     |
| ping  a la VM  | está realmente  | showvminfo      |     |
| aunque  ip a   |   enlazado al   | "bdd-nodo01" |  |     |
adaptador Host-
| muestre la IP  |     | findstr NIC |     |
| -------------- | --- | ----------- | --- |
Only correcto o
| correcta |     | que el  |     |
| -------- | --- | ------- | --- |
el firewall de
adaptador esté
Windows
en modo
bloquea ICMP
hostonly 
en ese
revisar reglas de
segmento
Firewall de
Windows para
permitir ICMP en
redes privadas
10

| ssh  desde el   | El servicio SSH  | Dentro de la VM:  |     |
| --------------- | ---------------- | ----------------- | --- |
| host falla con  | no está activo   | sudo systemctl    |     |
en la VM (poco
| “Connection  |     | status ssh |  y  |
| ------------ | --- | ---------- | --- |
probable si se
| refused” |     | sudo ufw  |     |
| -------- | --- | --------- | --- |
siguió la Fase
status  (debe
) o un firewall
|     |                  | estar  inactive |     |
| --- | ---------------- | --------------- | --- |
|     | interno ( ufw )  |                 |     |
por defecto en
está
Ubuntu Server
bloqueando el
si está activo y
|     | puerto  | bloqueando  |     |
| --- | --------- | ------------ | --- |
sudo ufw allow
)
22/tcp
| ssh  falla con    | La IP está mal    | Verificar IP      |     |
| ----------------- | ----------------- | ----------------- | --- |
| “Connection       | escrita el       | exacta en         |     |
| timed out” o “No  | adaptador no      | ambos nodos       |     |
| route to host”    | está realmente    | con  ip a         |    |
|                   | arriba ( ip link  | confirmar que     |     |
|                   | show enp0s3       | no se repitió la  |     |
misma dirección
|     | indica  DOWN ) o  |            |     |
| --- | ------------------ | ---------- | --- |
|     |                    | en         |     |
|     | ambos nodos        | bdd-nodo02 |     |
por error al
quedaron con la
|     | misma IP por   | copiar el archivo  |     |
| --- | -------------- | ------------------ | --- |
|     | error de copy- | de                 |     |
bdd-nodo01
paste
| ping bdd-      | Falta o está mal  | Revisar          | cat  |
| -------------- | ----------------- | ---------------- | ---- |
| nodo02  desde  | escrita la        | /etc/hosts       |      |
| bdd-nodo01     |   entrada en      | dentro de la VM  |      |
 de
| falla por nombre  | /etc/hosts | y corregir la    |     |
| ----------------- | ---------- | ---------------- | --- |
| pero funciona     | bdd-nodo01 | línea            |     |
| por IP            |            | correspondiente  |     |
(sección D)
| Al reiniciar la  | Cloud-init      | Verificar la      |     |
| ---------------- | --------------- | ----------------- | --- |
| VM la IP        | regeneró el     | existencia de un  |     |
| estática se      | archivo de      | archivo en        |     |
| pierde y vuelve  | Netplan porque  |                   |     |
/etc/cloud/clo
| a DHCP | la gestión de  |           |       |
| ------ | -------------- | --------- | ----- |
|        |                | ud.cfg.d/ |  que  |
red por cloud-
contenga
init no quedó
network:
deshabilitada en
{config:
esa instalación
|     |     | disabled} |  si  |
| --- | --- | --------- | ----- |
particular
no existe
crearlo
manualmente
con ese
contenido y
11

volver a aplicar
la configuración
de Netplan
G. Checklist de validación
Identifiqué correctamente el archivo de Netplan ( /etc/netplan/50-cloud-init.yaml ) y el
nombre real de la interfaz en cada VM.
Respaldé el archivo original antes de editarlo, en ambos nodos.
Configuré bdd-nodo01 con la IP estática 192.168.56.101/24 , sin gateway ni DNS.
Configuré bdd-nodo02 con la IP estática 192.168.56.102/24 , sin gateway ni DNS.
Corregí los permisos del archivo YAML a 600 en ambos nodos, si fue necesario.
Apliqué la configuración con netplan apply sin errores en ambos nodos.
Agregué las entradas de /etc/hosts ( bdd-nodo01 y bdd-nodo02 ) en ambas VMs.
Verifiqué ping exitoso desde el host Windows hacia ambas IPs.
Verifiqué ping exitoso entre bdd-nodo01 y bdd-nodo02 usando nombres de host.
Establecí conexión SSH exitosa desde el host hacia ambos nodos.
(Opcional) Agregué las entradas equivalentes en el archivo hosts de Windows.
Apagué ambas VMs de forma ordenada y tomé el snapshot fase06-completa en cada
una.
Puedo explicar por qué no se configuró gateway ni DNS, y en qué fase futura se resolvería
el acceso a internet de los nodos si fuera necesario.
Preparación para la siguiente fase
La Fase 7 (continuación del plan de crecimiento del laboratorio) requerirá:
• Ambos nodos con IP estática verificada y accesible por SSH desde el host (esta fase)
• Snapshot fase06-completa tomado en bdd-nodo01 y bdd-nodo02 
• Acceso SSH funcional ya que a partir de este punto la administración de los nodos podrá
hacerse de forma remota en lugar de usar la consola gráfica de VirtualBox
12

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

Fase 8 — Administración Básica de MariaDB
MGTI. Baltazar Martinez Galla
Continuación directa de la Fase 7. Ambos nodos tienen MariaDB 10.11 instalado,
configurado con utf8mb4 , con mysql_secure_installation ejecutado y snapshot
fase07-completa tomado. En esta fase se realiza la administración inicial del motor:
creación del esquema de prueba del laboratorio (que se usará en todas las fases de
distribución posteriores), gestión de usuarios y privilegios, habilitación del slow
query log, respaldo básico con mysqldump y conexión remota segura desde el host
Windows mediante DBeaver con túnel SSH. El acceso a internet (adaptador NAT de
la Fase 7) sigue activo en ambos nodos para eventuales actualizaciones. Todo el
trabajo se realizará exclusivamente por SSH desde el host, sin abrir la ventana
gráfica de VirtualBox.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Navegar las bases de datos del sistema de MariaDB ( information_schema 
performance_schema  mysql  sys ) y extraer información administrativa
mediante consultas SQL
 Diseñar y crear un esquema relacional pensado desde el inicio para su futura
distribución (fragmentación horizontal vertical e híbrida) en fases posteriores
 Comprender los cuatro niveles del sistema de privilegios de MariaDB (global
base de datos tabla y columna) y aplicarlos correctamente con GRANT y REVOKE 
 Diferenciar los plugins de autenticación unix_socket y mysql_native_password 
y elegir el adecuado para cada tipo de usuario y contexto
 Habilitar y consultar el slow query log interpretando sus entradas para
identificar consultas candidatas a optimización
 Ejecutar respaldos lógicos con mysqldump y comprender sus parámetros esenciales
distinguiendo entre un respaldo de esquema y un respaldo de datos completo
 Conectar una herramienta gráfica (DBeaver) al motor de MariaDB de forma segura
usando un túnel SSH en lugar de exponer el puerto  directamente a la red
 Ejecutar los comandos de monitoreo básico del motor ( SHOW STATUS  SHOW
PROCESSLIST  SHOW ENGINE INNODB STATUS ) e interpretar sus salidas más relevantes
 Cerrar la fase con el snapshot fase08-completa en ambos nodos en el estado
de mayor preparación alcanzado hasta ahora para las fases de distribución
1

B. Conceptos teóricos necesarios
1. Sistema de privilegios de MariaDB: cuatro niveles.
MariaDB controla el acceso mediante una jerarquía de cuatro niveles de granularidad,
evaluados de mayor a menor especificidad:
• Global ( GRANT ... ON *.* ) el privilegio aplica a cualquier base de datos y
cualquier tabla del servidor Se almacena en la tabla mysql.user 
• Base de datos ( GRANT ... ON basedatos.* ) aplica a todas las tablas de una
base de datos específica Se almacena en mysql.db 
• Tabla ( GRANT ... ON basedatos.tabla ) aplica solo a una tabla Se almacena
en mysql.tables_priv 
• Columna ( GRANT SELECT (col1, col2) ON ... ) aplica a columnas específicas
Se almacena en mysql.columns_priv 
Para cada privilegio, MariaDB también evalúa la dirección IP o nombre de host desde
el que conecta el usuario (parte @'host' en la definición). Un usuario se identifica
siempre por el par usuario@host , nunca solo por el nombre de usuario.
2. Plugins de autenticación: unix_socket y mysql_native_password .
MariaDB soporta múltiples plugins para verificar la identidad de quien conecta:
• unix_socket  el motor pregunta al kernel del sistema operativo si el proceso que
intenta conectar pertenece al usuario Unix cuyo nombre coincide con el usuario de
MariaDB Solo funciona desde el mismo servidor (socket local) No hay contraseña
que transmitir ni almacenar la identidad la garantiza el SO Es el método por
defecto para el usuario root en Ubuntu
• mysql_native_password  esquema clásico de contraseña con hash SHA doble
almacenado en mysql.user  Funciona tanto desde localhost como desde conexiones
TCP remotas Es el método que utilizará la herramienta DBeaver los scripts de
replicación (Fase ) y cualquier aplicación que conecte desde otro nodo
Ambos pueden coexistir en el mismo servidor para distintos usuarios.
3. Las cuatro bases de datos del sistema.
• information_schema  base de datos virtual (sin archivos reales) que expone
metadatos del servidor — tablas columnas índices vistas privilegios etc
Siempre está disponible en modo de solo lectura para cualquier usuario conectado
2

• mysql  base de datos física que almacena los datos del propio motor — tablas de
privilegios ( user  db  tables_priv ) rutinas almacenadas del sistema
historial de eventos Solo debe modificarse con instrucciones GRANT / REVOKE
y CREATE USER  nunca con INSERT / UPDATE directos
• performance_schema  base de datos de instrumentación (también virtual) que
registra métricas internas del motor — contadores de espera memory usage
ejecución de sentencias Se leerá en fases de diagnóstico
• sys  conjunto de vistas y procedimientos construidos sobre performance_schema
que ofrecen resúmenes legibles para humanos Disponible desde MariaDB +
4. Tipos de logs de MariaDB relevantes para este laboratorio.
• Error log ( /var/log/mysql/error.log ) errores de arranque advertencias del
motor y eventos críticos Siempre activo es el primer lugar donde buscar
problemas
• Slow query log registra consultas que superan un umbral de tiempo configurable
( long_query_time ) Esencial para detectar consultas mal optimizadas antes de
introducir la distribución en fases posteriores Se habilita en esta fase
• General query log registra todas las consultas recibidas Tiene un impacto
significativo en el rendimiento y en el tamaño del log solo debe activarse
puntualmente para depuración nunca de forma permanente No se habilita en esta
fase
• Binary log ( binlog ) registro de todos los cambios de datos en un formato
especial usado por la replicación Es la piedra angular de las Fases  y 
Se configurará en detalle entonces en esta fase solo se introduce el concepto
5. mysqldump : respaldo lógico.
mysqldump genera un archivo de texto que contiene las sentencias SQL necesarias para
recrear el esquema y/o los datos de una o varias bases de datos. Es el método de
respaldo más simple y portable; su principal limitación es que la restauración es
lenta en bases de datos grandes (hay que ejecutar miles de INSERT ) y no es
consistente con el estado exacto del binlog (para eso se usa mariabackup , que
se introduce como concepto en esta fase pero cuyo uso detallado corresponde a la
Fase 18 de recuperación). Para los volúmenes de este laboratorio, mysqldump es
completamente adecuado.
6. Túnel SSH para conexión remota segura.
El parámetro bind-address = 127.0.0.1 (configurado en la instalación de la Fase 7
y no modificado hasta la Fase 10) significa que MariaDB solo acepta conexiones TCP
desde el propio servidor. Una herramienta gráfica en el host Windows no puede
conectar directamente al puerto 3306 de una VM. La solución es un túnel SSH:
3

Text
DBeaver (Windows) → SSH → bdd-nodo01:22 → reenvío local → 127.0.0.1:3306
El cliente SSH abre una conexión cifrada al puerto 22 de bdd-nodo01 y “reenvía”
localmente el tráfico del puerto 3306: desde el punto de vista de MariaDB, la
conexión parece provenir de 127.0.0.1 (loopback del propio servidor). Esto
mantiene bind-address intacto y añade una capa de cifrado al canal de
administración, sin abrir ningún puerto adicional en la VM.
7. Diseño del esquema lab_bdd : pensado para la distribución.
El esquema que se crea en esta fase no es arbitrario. Cada decisión de diseño anticipa
los experimentos de las fases 13 a 16:
• La tabla clientes tiene una columna region ENUM('norte','sur','este','oeste') 
el predicado natural para la fragmentación horizontal de la Fase 
• La tabla pedidos replica ese campo region (redundancia controlada) para poder
fragmentarse independientemente de clientes sin necesidad de joins entre nodos
• La tabla productos mezcla columnas de consulta frecuente (precio stock) con
columnas de detalle pesado (descripcion ficha_tecnica imagen_url) la separación
natural para la fragmentación vertical de la Fase 
• Las relaciones entre tablas (claves foráneas) se conservan para trabajar con
consultas distribuidas en la Fase 
C. Procedimiento paso a paso
Paso 1 — Iniciar ambas VMs en modo headless y conectarse por SSH.
Arrancar bdd-nodo01 y bdd-nodo02 . La mayor parte del trabajo de esta fase se
realiza en bdd-nodo01 ; los pasos que corresponden a bdd-nodo02 se indican
explícitamente.
Paso 2 — Explorar las bases de datos del sistema.
Antes de crear nada nuevo, familiarizarse con las bases de datos ya existentes
ejecutando las consultas de exploración de la sección D.1 dentro de sudo mariadb .
Paso 3 — Crear el esquema del laboratorio lab_bdd .
Ejecutar el script de creación de tablas de la sección D.2. Este esquema es el mismo
en ambos nodos por ahora; en la Fase 9 se diseñará cómo distribuirlo.
4

Paso 4 — Insertar los datos de prueba.
Ejecutar el script de la sección D.3 para poblar clientes , productos , pedidos
y detalle_pedidos con un conjunto inicial de datos representativos.
Paso 5 — Crear y verificar los usuarios del laboratorio.
Crear dos usuarios con mysql_native_password : lab_admin@'localhost' con privilegios
amplios sobre lab_bdd , y app_user@'localhost' con privilegios de solo
lectura/escritura de datos (no de estructura). Ver sección D.4.
Paso 6 — Verificar el esquema de privilegios aplicado.
Usar SHOW GRANTS e information_schema para confirmar que los privilegios quedaron
exactamente como se planeó (sección D.5).
Paso 7 — Habilitar el slow query log.
Crear el archivo de configuración 99-lab-logs.cnf en mariadb.conf.d/ y reiniciar
el servicio para activarlo (sección D.6). Generar una consulta lenta artificial para
verificar que se registra.
Paso 8 — Ejecutar los comandos de monitoreo del motor.
Practicar los comandos de diagnóstico instantáneo de MariaDB ( SHOW STATUS ,
SHOW PROCESSLIST , SHOW ENGINE INNODB STATUS ) e interpretar las métricas más
importantes para el laboratorio (sección D.7).
Paso 9 — Realizar un respaldo básico con mysqldump .
Generar respaldos del esquema (solo DDL) y de esquema más datos de lab_bdd ,
guardados en la carpeta de trabajo del laboratorio dentro del nodo (sección D.8).
Paso 10 — Instalar DBeaver en el host Windows y configurar la conexión por túnel SSH.
DBeaver Community Edition es gratuita y no requiere instalación de JDK separado
en versiones recientes. La conexión a cada nodo se configura usando las credenciales
SSH de bddadmin y el usuario lab_admin de MariaDB (sección D.9).
Paso 11 — Repetir los Pasos 3 a 9 en bdd-nodo02 .
El esquema lab_bdd , los datos de prueba, los usuarios y la configuración de logs
deben ser idénticos en ambos nodos. Esto garantiza que las fases de replicación
puedan iniciarse desde un estado coherente.
Paso 12 — Apagar ambas VMs y tomar el snapshot de cierre de fase.
Ver sección D.10.
Paso 13 — Validar con el checklist de la sección G.
5

D. Comandos completos
Los comandos marcados (VM) se ejecutan dentro de una sesión SSH en la VM
indicada. Los marcados (host) se ejecutan en PowerShell en Windows. Los bloques
MariaDB> se ejecutan dentro del prompt del motor, accedido con sudo mariadb .
D.1 Iniciar las VMs y conectarse por SSH (host)
PowerShell
VBoxManage startvm "bdd-nodo01" --type headless
VBoxManage startvm "bdd-nodo02" --type headless
Esperar 20–30 segundos y conectarse:
PowerShell
ssh bddadmin@192.168.56.101
D.2 Explorar las bases de datos del sistema (VM — bdd-nodo01)
Bash
sudo mariadb
Dentro del prompt MariaDB [(none)]> :
6

SQL
-- Listar todas las bases de datos del sistema
SHOW DATABASES;
-- ¿Qué tablas existen en la base de datos del sistema 'mysql'?
SHOW TABLES IN mysql;
-- Tabla de usuarios: quién tiene acceso y con qué plugin de autenticación
SELECT User, Host, plugin, authentication_string IS NOT NULL
AS tiene_password
FROM mysql.user;
-- Ver todos los privilegios globales actuales
SELECT User, Host, Select_priv, Insert_priv, Super_priv, Repl_slave_priv
FROM mysql.user;
-- Cuántas tablas existen en cada base de datos del sistema
SELECT TABLE_SCHEMA AS base_datos,
COUNT(*) AS num_tablas
FROM information_schema.TABLES
GROUP BY TABLE_SCHEMA
ORDER BY num_tablas DESC;
-- Variables de configuración activas más relevantes
SHOW VARIABLES LIKE 'character%';
SHOW VARIABLES LIKE 'collation%';
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'datadir';
SHOW VARIABLES LIKE 'log_error';
EXIT;
D.3 Crear el esquema del laboratorio lab_bdd (VM — bdd-nodo01)
Crear el archivo del script SQL para mantener el DDL documentado:
7

Bash
cat > /tmp/crear_schema_lab_bdd.sql << 'EOF'
-- =============================================================
-- Esquema del Laboratorio de Bases de Datos Distribuidas
-- Creado en la Fase 8. Diseñado para fragmentación futura.
-- =============================================================
CREATE DATABASE IF NOT EXISTS lab_bdd
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE lab_bdd;
-- -----------------------------------------------------------
-- CLIENTES: campo 'region' -> fragmentación horizontal (F13)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
id INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(100) NOT NULL,
apellido VARCHAR(100) NOT NULL,
email VARCHAR(150) UNIQUE,
telefono VARCHAR(20),
region ENUM('norte','sur','este','oeste') NOT NULL,
ciudad VARCHAR(100),
fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Fragmentación horizontal por region (Fase 13)';
-- -----------------------------------------------------------
-- PRODUCTOS: columnas básicas + detalle -> frag. vertical (F14)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS productos (
id INT AUTO_INCREMENT PRIMARY KEY,
sku VARCHAR(50) NOT NULL UNIQUE,
nombre VARCHAR(150) NOT NULL,
categoria VARCHAR(50),
precio DECIMAL(10,2) NOT NULL,
stock INT DEFAULT 0,
-- Columnas de detalle (candidatas a nodo separado en Fase 14)
descripcion TEXT,
ficha_tecnica TEXT,
imagen_url VARCHAR(255),
peso_kg DECIMAL(6,3),
fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Fragmentación vertical: basico vs detalle
(Fase 14)';
-- -----------------------------------------------------------
-- PEDIDOS: campo 'region' propio -> frag. horizontal (F13)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos (
id INT AUTO_INCREMENT PRIMARY KEY,
cliente_id INT NOT NULL,
8

region ENUM('norte','sur','este','oeste') NOT NULL,
fecha_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
estado ENUM('pendiente','procesado','enviado',
'entregado','cancelado') DEFAULT 'pendiente',
total DECIMAL(10,2),
FOREIGN KEY (cliente_id) REFERENCES clientes(id)
ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Fragmentación horizontal por region (Fase 13)';
-- -----------------------------------------------------------
-- DETALLE_PEDIDOS: tabla de relación N:M
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS detalle_pedidos (
id INT AUTO_INCREMENT PRIMARY KEY,
pedido_id INT NOT NULL,
producto_id INT NOT NULL,
cantidad INT NOT NULL CHECK (cantidad > 0),
precio_unitario DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2) GENERATED ALWAYS AS
(cantidad * precio_unitario) STORED,
FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (producto_id) REFERENCES productos(id)
ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Detalle de lineas de pedido';
-- Confirmar la creación
SHOW TABLES;
EOF
Ejecutar el script:
Bash
sudo mariadb < /tmp/crear_schema_lab_bdd.sql
Verificar que las cuatro tablas existen:
Bash
sudo mariadb -e "SHOW TABLES IN lab_bdd;"
9

D.4 Insertar datos de prueba (VM — bdd-nodo01)
Bash
cat > /tmp/insertar_datos_lab_bdd.sql << 'EOF'
USE lab_bdd;
-- -------------------- CLIENTES (20 registros, 5 por region) ------------
--------
INSERT INTO clientes (nombre, apellido, email, telefono, region,
ciudad) VALUES
-- Norte
('Ana', 'Gutiérrez', 'ana.gutierrez@lab.test', '8181000001',
'norte', 'Monterrey'),
('Carlos', 'Mendoza', 'carlos.mendoza@lab.test', '6141000002',
'norte', 'Chihuahua'),
('Laura', 'Ibarra', 'laura.ibarra@lab.test', '6641000003',
'norte', 'Tijuana'),
('Roberto', 'Soto', 'roberto.soto@lab.test', '6621000004',
'norte', 'Hermosillo'),
('Verónica', 'Reyes', 'veronica.reyes@lab.test', '8711000005',
'norte', 'Torreón'),
-- Sur
('Miguel', 'Castro', 'miguel.castro@lab.test', '9991000006',
'sur', 'Mérida'),
('Sofía', 'Domínguez', 'sofia.dominguez@lab.test', '9981000007',
'sur', 'Cancún'),
('Jorge', 'Hernández', 'jorge.hernandez@lab.test', '9511000008',
'sur', 'Oaxaca'),
('Patricia', 'Vázquez', 'patricia.vazquez@lab.test', '9931000009',
'sur', 'Villahermosa'),
('Ernesto', 'Luna', 'ernesto.luna@lab.test', '9611000010',
'sur', 'Tuxtla Gtz.'),
-- Este
('Isabel', 'Morales', 'isabel.morales@lab.test', '2291000011',
'este', 'Veracruz'),
('Héctor', 'Jiménez', 'hector.jimenez@lab.test', '2281000012',
'este', 'Xalapa'),
('Daniela', 'Torres', 'daniela.torres@lab.test', '8331000013',
'este', 'Tampico'),
('Alejandro','Ríos', 'alejandro.rios@lab.test', '9211000014',
'este', 'Coatzacoalcos'),
('Fernanda', 'Peña', 'fernanda.pena@lab.test', '7821000015',
'este', 'Poza Rica'),
-- Oeste
('Arturo', 'Flores', 'arturo.flores@lab.test', '3331000016',
'oeste', 'Guadalajara'),
('Carmen', 'Rojas', 'carmen.rojas@lab.test', '3121000017',
'oeste', 'Colima'),
10

('Ramón', 'Salinas', 'ramon.salinas@lab.test', '3111000018',
'oeste', 'Tepic'),
('Lucía', 'Medina', 'lucia.medina@lab.test', '4431000019',
'oeste', 'Morelia'),
('Eduardo', 'Vargas', 'eduardo.vargas@lab.test', '4491000020',
'oeste', 'Aguascalientes');
-- -------------------- PRODUCTOS (10 registros) --------------------
INSERT INTO productos (sku, nombre, categoria, precio, stock,
descripcion, ficha_tecnica, peso_kg) VALUES
('ELEC-001', 'Monitor 24" FHD', 'Electrónica', 3500.00, 25,
'Monitor LED 24 pulgadas Full HD 1920x1080, 75Hz, panel IPS.',
'Resolución: 1920x1080 | Frecuencia: 75 Hz | Panel: IPS | Entradas:
HDMI, VGA',
3.200),
('ELEC-002', 'Teclado Mecánico TKL', 'Electrónica', 950.00, 40,
'Teclado mecánico TKL con switches azules, retroiluminación RGB.',
'Switches: Blue | Layout: TKL 87 teclas | Retroiluminación: RGB |
Conector: USB-C',
0.850),
('ELEC-003', 'Mouse Ergonómico', 'Electrónica', 480.00, 60,
'Mouse inalámbrico ergonómico, sensor óptico 1600 DPI, receptor
USB nano.',
'DPI: 800/1200/1600 | Batería: AA 12 meses | Receptor: nano USB |
Botones: 6',
0.120),
('COMP-001', 'SSD 500 GB SATA', 'Almacenamiento', 1200.00, 30,
'Unidad de estado sólido SATA III 500 GB, velocidad lectura 560 MB/s.',
'Capacidad: 500 GB | Interfaz: SATA III | Lectura: 560 MB/s | Escritura:
520 MB/s',
0.060),
('COMP-002', 'Memoria RAM 16 GB', 'Almacenamiento', 1850.00, 20,
'Módulo de memoria DDR4 16 GB 3200 MHz, latencia CL16.',
'Capacidad: 16 GB | Tipo: DDR4 | Velocidad: 3200 MHz | Latencia: CL16',
0.040),
('RED-001', 'Switch 8 puertos', 'Redes', 650.00, 15,
'Switch no administrado 8 puertos Gigabit Ethernet 10/100/1000.',
'Puertos: 8 x GbE | Capacidad: 16 Gbps | Formato: Sobremesa | PoE: No',
0.350),
('RED-002', 'Cable UTP Cat6 5m', 'Redes', 85.00, 120,
'Cable de red UTP categoría 6 de 5 metros con conectores
RJ45 moldeados.',
'Categoría: Cat6 | Longitud: 5 m | Conector: RJ45 |
Apantallamiento: UTP',
0.100),
('PER-001', 'Silla Gamer Pro', 'Mobiliario', 4200.00, 8,
'Silla de oficina/gaming con soporte lumbar, reposabrazos 4D y
reclinación 135°.',
'Material: Cuero PU | Reclinación: 90-135° | Reposabrazos: 4D | Peso máx:
11

120 kg',
18.500),
('PER-002', 'Escritorio L 140 cm', 'Mobiliario', 2800.00, 5,
'Escritorio en forma de L 140x120 cm con superficie de melamina 25 mm.',
'Medidas: 140x120x75 cm | Material: MDP 25 mm | Acabado: Melamina |
Color: Roble',
35.000),
('ACC-001', 'Hub USB-C 7 en 1', 'Accesorios', 420.00, 50,
'Hub multifunción USB-C con HDMI 4K, 3 USB-A 3.0, SD, MicroSD y USB-C
PD 100W.',
'Entradas: 1 USB-C | Salidas: HDMI 4K, 3xUSB-A, SD, MicroSD | PD: 100W',
0.080);
-- -------------------- PEDIDOS (20 registros, mix de regiones y estados)
--------------------
INSERT INTO pedidos (cliente_id, region, estado, total) VALUES
( 1, 'norte', 'entregado', 4450.00),
( 2, 'norte', 'enviado', 1430.00),
( 3, 'norte', 'procesado', 3500.00),
( 4, 'norte', 'pendiente', 2800.00),
( 5, 'norte', 'entregado', 735.00),
( 6, 'sur', 'entregado', 5050.00),
( 7, 'sur', 'enviado', 2050.00),
( 8, 'sur', 'procesado', 565.00),
( 9, 'sur', 'pendiente', 4620.00),
(10, 'sur', 'cancelado', 850.00),
(11, 'este', 'entregado', 1200.00),
(12, 'este', 'enviado', 3980.00),
(13, 'este', 'procesado', 6020.00),
(14, 'este', 'pendiente', 505.00),
(15, 'este', 'entregado', 1650.00),
(16, 'oeste', 'entregado', 4650.00),
(17, 'oeste', 'enviado', 3285.00),
(18, 'oeste', 'procesado', 480.00),
(19, 'oeste', 'pendiente', 7000.00),
(20, 'oeste', 'entregado', 3220.00);
-- -------------------- DETALLE_PEDIDOS --------------------
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad,
precio_unitario) VALUES
(1, 1, 1, 3500.00), (1, 3, 2, 480.00),
(2, 2, 1, 950.00), (2, 3, 1, 480.00),
(3, 1, 1, 3500.00),
(4, 9, 1, 2800.00),
(5, 7, 5, 85.00), (5, 6, 1, 650.00),
(6, 8, 1, 4200.00), (6, 2, 1, 950.00),
(7, 5, 1, 1850.00), (7, 3, 1, 480.00),
(8, 6, 1, 650.00), (8, 7, 1, 85.00),
(9, 4, 1, 1200.00), (9, 5, 1, 1850.00), (9, 8, 1, 4200.00),
(10, 2, 1, 950.00),
12

(11, 4, 1, 1200.00),
(12, 1, 1, 3500.00), (12, 10, 1, 420.00),
(13, 8, 1, 4200.00), (13, 9, 1, 2800.00),
(14, 7, 3, 85.00), (14, 6, 1, 650.00),
(15, 5, 1, 1850.00),
(16, 8, 1, 4200.00), (16, 3, 1, 480.00),
(17, 1, 1, 3500.00), (17, 7, 3, 85.00),
(18, 3, 1, 480.00),
(19, 9, 1, 2800.00), (19, 1, 1, 3500.00),
(20, 1, 1, 3500.00), (20, 7, 1, 85.00);
-- Actualizar totales calculados en pedidos
UPDATE pedidos p
SET total = (
SELECT SUM(subtotal)
FROM detalle_pedidos dp
WHERE dp.pedido_id = p.id
);
-- Resumen final
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM
detalle_pedidos;
EOF
Bash
sudo mariadb < /tmp/insertar_datos_lab_bdd.sql
Verificar el conteo de registros:
13

Bash
sudo mariadb -e "
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM
lab_bdd.clientes UNION ALL
SELECT 'productos', COUNT(*) FROM
lab_bdd.productos UNION ALL
SELECT 'pedidos', COUNT(*) FROM
lab_bdd.pedidos UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM
lab_bdd.detalle_pedidos;
"
Salida esperada:
Text
+-----------------+------------+
| tabla | registros |
+-----------------+------------+
| clientes | 20 |
| productos | 10 |
| pedidos | 20 |
| detalle_pedidos | 36 |
+-----------------+------------+
14

D.5 Crear los usuarios del laboratorio (VM — bdd-nodo01)
Bash
sudo mariadb << 'EOF'
-- --------------------------------------------------------
-- Usuario: lab_admin
-- Propósito: administración del esquema lab_bdd desde el
-- host Windows vía DBeaver + túnel SSH, y desde
-- scripts de mantenimiento locales.
-- Autenticación: mysql_native_password (necesario para DBeaver)
-- --------------------------------------------------------
CREATE USER IF NOT EXISTS 'lab_admin'@'localhost'
IDENTIFIED BY 'LabAdmin_2025!';
GRANT ALL PRIVILEGES ON lab_bdd.* TO 'lab_admin'@'localhost';
-- Acceso a information_schema y performance_schema en modo lectura
-- (para que DBeaver pueda explorar metadatos)
GRANT SELECT ON information_schema.* TO 'lab_admin'@'localhost';
GRANT SELECT ON performance_schema.* TO 'lab_admin'@'localhost';
-- --------------------------------------------------------
-- Usuario: app_user
-- Propósito: simular un usuario de aplicación; solo puede
-- leer y escribir datos, nunca modificar el esquema.
-- --------------------------------------------------------
CREATE USER IF NOT EXISTS 'app_user'@'localhost'
IDENTIFIED BY 'AppUser_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.*
TO 'app_user'@'localhost';
-- --------------------------------------------------------
-- Aplicar los cambios de privilegios de inmediato
-- --------------------------------------------------------
FLUSH PRIVILEGES;
-- Verificar que los usuarios quedaron registrados
SELECT User, Host, plugin FROM mysql.user
WHERE User IN ('lab_admin', 'app_user', 'root')
ORDER BY User;
EOF
Importante: documentar ambas contraseñas en
C:\LabBDD\Snapshots-Notas\fase08-notas.txt . Son credenciales de laboratorio
intencionalmente simples; nunca usar contraseñas con este patrón en producción.
15

D.6 Verificar los privilegios otorgados (VM — bdd-nodo01)
Bash
sudo mariadb << 'EOF'
-- Ver privilegios de cada usuario
SHOW GRANTS FOR 'lab_admin'@'localhost';
SHOW GRANTS FOR 'app_user'@'localhost';
-- Confirmar a través de information_schema
SELECT GRANTEE, TABLE_SCHEMA, PRIVILEGE_TYPE, IS_GRANTABLE
FROM information_schema.SCHEMA_PRIVILEGES
WHERE TABLE_SCHEMA = 'lab_bdd'
ORDER BY GRANTEE, PRIVILEGE_TYPE;
EOF
Probar que app_user puede leer datos pero NO puede modificar el esquema:
Bash
# Debe funcionar: SELECT es un privilegio de app_user
mariadb -u app_user -p'AppUser_2025!' lab_bdd \
-e "SELECT COUNT(*) AS total_clientes FROM clientes;"
# Debe fallar con Access denied: DROP no fue otorgado a app_user
mariadb -u app_user -p'AppUser_2025!' lab_bdd \
-e "DROP TABLE clientes;" 2>&1 | grep -i "access denied\|error"
D.7 Habilitar el slow query log (VM — bdd-nodo01 y bdd-nodo02)
Crear el archivo de configuración de logs:
Bash
sudo nano /etc/mysql/mariadb.conf.d/99-lab-logs.cnf
Contenido completo (idéntico en ambos nodos):
16

Text
# Configuración de logs para el Laboratorio BDD
# Creado en la Fase 8. Cargado después de 50-server.cnf.
# No editar 50-server.cnf directamente.
[mariadb]
# --- Slow Query Log ---
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 2
# Registrar también consultas que no usan índices (útil para diagnóstico)
log_queries_not_using_indexes = 0
# --- General Query Log (deshabilitado; activar solo para depuración
puntual) ---
general_log = 0
general_log_file = /var/log/mysql/mariadb-general.log
Guardar con Ctrl+O , Enter , Ctrl+X . Reiniciar MariaDB:
Bash
sudo systemctl restart mariadb
sudo systemctl status mariadb
Verificar que el slow query log está activo dentro del motor:
Bash
sudo mariadb -e "SHOW VARIABLES LIKE 'slow_query%';"
sudo mariadb -e "SHOW VARIABLES LIKE 'long_query_time';"
Generar una consulta artificialmente lenta para confirmar que se registra
(usa SLEEP() para simular una consulta que tarda más de 2 segundos):
Bash
sudo mariadb lab_bdd -e "SELECT SLEEP(3), COUNT(*) FROM clientes;"
Consultar el log para verificar que la entrada apareció:
17

Bash
sudo tail -20 /var/log/mysql/mariadb-slow.log
| Se debe ver una entrada con  |  apuntando al  | .   |
| ---------------------------- | -------------- | --- |
Query_time: 3.xxx SELECT SLEEP(3)
18

D.8 Comandos de monitoreo del motor (VM — bdd-nodo01)
Bash
sudo mariadb << 'EOF'
-- ---- Estado global del servidor ----
-- Conexiones acumuladas desde el último arranque
SHOW GLOBAL STATUS LIKE 'Connections';
-- Conexiones activas en este momento
SHOW GLOBAL STATUS LIKE 'Threads_connected';
-- Consultas ejecutadas desde el arranque
SHOW GLOBAL STATUS LIKE 'Questions';
-- Bytes enviados y recibidos
SHOW GLOBAL STATUS LIKE 'Bytes_%';
-- Operaciones de InnoDB (lecturas/escrituras de páginas)
SHOW GLOBAL STATUS LIKE 'Innodb_pages_%';
-- ---- Procesos activos ----
-- Lista todos los hilos de conexión activos en este momento
SHOW FULL PROCESSLIST;
-- ---- Estado de InnoDB ----
-- Salida extensa; incluye buffer pool, transacciones activas,
-- locks, I/O. Se usa para diagnóstico avanzado.
SHOW ENGINE INNODB STATUS\G
-- ---- Resumen de tablas del laboratorio ----
SELECT TABLE_NAME AS tabla,
TABLE_ROWS AS filas_aprox,
ROUND(DATA_LENGTH/1024, 1) AS datos_KB,
ROUND(INDEX_LENGTH/1024, 1) AS indices_KB
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'lab_bdd'
ORDER BY DATA_LENGTH DESC;
-- ---- Consulta de negocio de ejemplo para verificar los datos ----
SELECT c.region,
COUNT(DISTINCT c.id) AS clientes,
COUNT(p.id) AS pedidos,
ROUND(SUM(p.total), 2) AS ingresos_total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.region
ORDER BY ingresos_total DESC;
EOF
D.9 Respaldo básico con mysqldump (VM — bdd-nodo01)
Crear la carpeta de respaldos dentro del nodo:
19

Bash
sudo mkdir -p /opt/lab_bdd_backups
sudo chown bddadmin:bddadmin /opt/lab_bdd_backups
Respaldo 1 — Solo estructura (DDL):
Bash
mysqldump -u lab_admin -p'LabAdmin_2025!' \
--no-data \
--routines \
--triggers \
--single-transaction \
lab_bdd > /opt/lab_bdd_backups/lab_bdd_schema_$(date +%Y%m%d).sql
ls -lh /opt/lab_bdd_backups/
Respaldo 2 — Estructura y datos completos:
Bash
mysqldump -u lab_admin -p'LabAdmin_2025!' \
--routines \
--triggers \
--single-transaction \
--quick \
lab_bdd > /opt/lab_bdd_backups/lab_bdd_completo_$(date +%Y%m%d).sql
ls -lh /opt/lab_bdd_backups/
wc -l /opt/lab_bdd_backups/lab_bdd_completo_$(date +%Y%m%d).sql
Verificar que el archivo de respaldo es válido (primeras y últimas líneas):
Bash
head -20 /opt/lab_bdd_backups/lab_bdd_completo_$(date +%Y%m%d).sql
tail -10 /opt/lab_bdd_backups/lab_bdd_completo_$(date +%Y%m%d).sql
La última línea debe ser -- Dump completed on ... seguida de la marca de tiempo.
20

Sobre los parámetros usados:
• --single-transaction  toma un snapshot consistente de InnoDB sin bloquear
las tablas durante el respaldo (equivalente a un START TRANSACTION interno)
• --quick  descarga las filas de a una en lugar de cargar toda la tabla en
memoria esencial para bases de datos grandes
• --routines y --triggers  incluye procedimientos funciones y disparadores
si los hubiera (en este laboratorio no hay aún pero es buena práctica incluirlos)
D.10 Conectar DBeaver desde el host Windows con túnel SSH
Instalación de DBeaver (host Windows):
Descargar DBeaver Community Edition desde https://dbeaver.io/download/
(archivo .exe o .zip para Windows). No requiere instalación de JDK separado
en versiones 23+; el JDK embebido viene incluido en el instalador.
Configurar la conexión con túnel SSH en DBeaver:
 Abrir DBeaver → Archivo → Nueva conexión → seleccionar MariaDB
 En la pestaña Principal
• Host 127.0.0.1
• Puerto 3306
• Base de datos lab_bdd
• Usuario lab_admin
• Contraseña LabAdmin_2025!
 En la pestaña SSH
• Marcar Use SSH Tunnel
• Host/IP: 192.168.56.101
• Puerto SSH: 22
• Usuario bddadmin
• Método de autenticación Password
• Contraseña SSH: (contraseña definida para bddadmin en la Fase )
 Hacer clic en Test Connection  DBeaver primero abre el túnel SSH al puerto
 de la VM y luego conecta al 127.0.0.1:3306 que el túnel reenvía
 Si la prueba es exitosa Finalizar 
21

Repetir los pasos para crear una segunda conexión apuntando a 192.168.56.102
( bdd-nodo02 ), con los mismos usuarios y contraseñas de MariaDB.
Si DBeaver solicita instalar el driver JDBC de MariaDB, aceptar y dejar que lo
descargue automáticamente (requiere internet en el host Windows, no en la VM).
D.11 Repetir los Pasos D.3 a D.9 en bdd-nodo02 (VM — bdd-nodo02)
Conectarse a bdd-nodo02 por SSH y ejecutar exactamente los mismos scripts.
El contenido de lab_bdd debe ser idéntico en ambos nodos:
PowerShell
# Desde el host, abrir una segunda terminal SSH
ssh bddadmin@192.168.56.102
Dentro de bdd-nodo02 , ejecutar en orden:
22

Bash
# Copiar los scripts desde bdd-nodo01 usando scp (ejecutar desde
bdd-nodo02)
scp bddadmin@192.168.56.101:/tmp/crear_schema_lab_bdd.sql /tmp/
scp bddadmin@192.168.56.101:/tmp/insertar_datos_lab_bdd.sql /tmp/
# Aplicar el esquema y los datos
sudo mariadb < /tmp/crear_schema_lab_bdd.sql
sudo mariadb < /tmp/insertar_datos_lab_bdd.sql
# Crear usuarios
sudo mariadb << 'EOF'
CREATE USER IF NOT EXISTS 'lab_admin'@'localhost'
IDENTIFIED BY 'LabAdmin_2025!';
GRANT ALL PRIVILEGES ON lab_bdd.* TO 'lab_admin'@'localhost';
GRANT SELECT ON information_schema.* TO 'lab_admin'@'localhost';
GRANT SELECT ON performance_schema.* TO 'lab_admin'@'localhost';
CREATE USER IF NOT EXISTS 'app_user'@'localhost'
IDENTIFIED BY 'AppUser_2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_bdd.*
TO 'app_user'@'localhost';
FLUSH PRIVILEGES;
EOF
# Crear configuración de logs (idéntica a bdd-nodo01)
sudo tee /etc/mysql/mariadb.conf.d/99-lab-logs.cnf > /dev/null << 'EOF'
[mariadb]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 2
log_queries_not_using_indexes = 0
general_log = 0
general_log_file = /var/log/mysql/mariadb-general.log
EOF
sudo systemctl restart mariadb
# Crear carpeta de respaldos y ejecutar respaldo inicial
sudo mkdir -p /opt/lab_bdd_backups
sudo chown bddadmin:bddadmin /opt/lab_bdd_backups
mysqldump -u lab_admin -p'LabAdmin_2025!' \
--routines --triggers --single-transaction --quick \
lab_bdd > /opt/lab_bdd_backups/lab_bdd_completo_$(date +%Y%m%d).sql
# Verificación final
sudo mariadb -e "
SELECT 'clientes', COUNT(*) FROM lab_bdd.clientes UNION ALL
SELECT 'productos', COUNT(*) FROM lab_bdd.productos UNION ALL
SELECT 'pedidos', COUNT(*) FROM lab_bdd.pedidos UNION ALL
SELECT 'detalle', COUNT(*) FROM lab_bdd.detalle_pedidos;
"
23

D.12 Apagar ambas VMs y tomar el snapshot fase08-completa (host)
Desde cada sesión SSH (ejecutar en cada nodo):
Bash
sudo poweroff
Confirmar desde el host que ambas VMs están detenidas:
PowerShell
VBoxManage list runningvms
La salida debe estar vacía. Tomar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase08-completa" `
--description "lab_bdd creada: 20 clientes, 10 productos, 20 pedidos,
35 detalles. Usuarios lab_admin y app_user. Slow log activo. Respaldo
mysqldump generado."
VBoxManage snapshot "bdd-nodo02" take "fase08-completa" `
--description "lab_bdd creada: idéntica a bdd-nodo01. Usuarios lab_admin y
app_user. Slow log activo. Respaldo mysqldump generado."
Confirmar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
Cada VM debe mostrar cuatro snapshots en orden: fase05-completa , fase06-completa ,
fase07-completa y fase08-completa .
24

E. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen los siguientes puntos
| en ambos nodos ( | bdd-nodo01 |     |  y  bdd-nodo02 | ):  |     |     |     |
| ---------------- | ---------- | --- | -------------- | --- | --- | --- | --- |
 SHOW DATABASES;  dentro de  sudo mariadb  muestra  lab_bdd  además de las
cuatro bases de datos del sistema La base de datos   no existe
test
|                       |            |                    |  muestra exactamente cuatro tablas  |     |     |          |    |
| ----------------------- | ---------- | ------------------ | ------------------------------------ | --- | --- | -------- | --- |
| SHOW TABLES IN lab_bdd; |            |                    |                                      |     |     | clientes |     |
| productos               |   pedidos |   detalle_pedidos |                                      |    |     |          |     |
 La consulta de conteo confirma  clientes  productos  pedidos y 
registros de detalle
|   |     |     |     |  muestra  |     |     |     |
| --- | --- | --- | --- | --------- | --- | --- | --- |
SHOW GRANTS FOR 'lab_admin'@'localhost'; GRANT ALL PRIVILEGES ON
| lab_bdd.* |    |     |     |     |     |     |     |
| --------- | --- | --- | --- | --- | --- | --- | --- |
 SHOW GRANTS FOR 'app_user'@'localhost';  muestra únicamente los privilegios
SELECT, INSERT, UPDATE, DELETE  sobre  lab_bdd.*  y ninguno adicional
|  El intento de                       |            |  con  |          |  falla con                      |               |    |     |
| -------------------------------------- | ---------- | ----- | -------- | ------------------------------- | ------------- | --- | --- |
|                                        | DROP TABLE |       | app_user |                                 | Access denied |     |     |
|                                      |            |       |          |  devuelve                       |              |     |     |
| SHOW VARIABLES LIKE 'slow_query_log';  |            |       |          |                                 | ON            |     |     |
|                                      |            |       |          |  devuelve                       |               |    |     |
| SHOW VARIABLES LIKE 'long_query_time'; |            |       |          |                                 | 2.000000      |     |     |
|  El archivo                          |            |       |          |  existe y contiene al menos una |               |     |     |
/var/log/mysql/mariadb-slow.log
| entrada del  | SELECT SLEEP(3) |     |  ejecutado en la sección D |     |     |     |     |
| ------------ | --------------- | --- | ----------------------------- | --- | --- | --- | --- |
 El archivo de respaldo  lab_bdd_completo_YYYYMMDD.sql  existe en
 con un tamaño mayor a cero y la línea
| /opt/lab_bdd_backups/ |            |     |     |     |     | -- Dump |     |
| --------------------- | ---------- | --- | --- | --- | --- | ------- | --- |
| completed on          |  al final |     |     |     |     |         |     |
 Desde DBeaver en el host Windows la conexión con túnel SSH a  bdd-nodo01  y
| a                                             |  abre exitosamente y muestra las tablas de  |     |     |     |         |    |     |
| --------------------------------------------- | ------------------------------------------- | --- | --- | --- | ------- | --- | --- |
| bdd-nodo02                                    |                                             |     |     |     | lab_bdd |     |     |
|  La conectividad Host-Only sigue intacta  |                                             |     |     |     |         |  y  |     |
ping 192.168.56.101
| ping 192.168.56.102 |     |  responden desde el host Windows |     |     |     |     |     |
| ------------------- | --- | --------------------------------- | --- | --- | --- | --- | --- |
 Los snapshots  fase08-completa  existen en  bdd-nodo01  y  bdd-nodo02 
 Las credenciales de  lab_admin  y  app_user  están documentadas en
| C:\LabBDD\Snapshots-Notas\fase08-notas.txt |     |     |     |     |    |     |     |
| ------------------------------------------ | --- | --- | --- | --- | --- | --- | --- |
25

F. Problemas comunes y soluciones
| Problema |     | Causa probable |     | Solución |     |     |
| -------- | --- | -------------- | --- | -------- | --- | --- |
CREATE USER  falla con  ERROR  El usuario ya existe de un  Usar  DROP USER IF EXISTS
1396: Operation CREATE USER  intento anterior fallido 'lab_admin'@'localhost';
| failed |     |     |     | antes de volver a crear o usar la  |                     |     |
| ------ | --- | --- | --- | ----------------------------------- | ------------------- | --- |
|        |     |     |     | sintaxis                            | CREATE USER IF NOT  |     |
EXISTS
SHOW GRANTS  devuelve un  El usuario se creó pero  Verificar con  SELECT User, Host
error de  no such grant GRANT  no se ejecutó  FROM mysql.user;  que el
|     |     | correctamente o se  |      | usuario y el host coincidan    |     |     |
| --- | --- | -------------------- | ---- | ------------------------------ | --- | --- |
|     |     | especificó un        |      |                                |     |     |
|     |     |                      | host | exactamente con lo que se usó  |     |     |
|     |     | diferente            |      | en  GRANT                      |     |     |
mysqldump  falla con  Access  La versión de  Añadir el flag  --no-tablespaces
denied; you need the  MariaDB/MySQL es ≥  al comando de  mysqldump  o
PROCESS privilege  y  mysqldump   usar  root  con  sudo   sudo
|     |     | necesita  SHOW MASTER  |     |     |     |     |
| --- | --- | ---------------------- | --- | --- | --- | --- |
mysqldump -u root ...
|     |     | STATUS  al usar    | --    |     |     |     |
| --- | --- | ------------------ | ----- | --- | --- | --- |
|     |     | single-transaction |  sin  |     |     |     |
el flag  --no-
tablespaces
DBeaver muestra  El túnel SSH no se  En DBeaver verificar que la
Communications link  estableció correctamente  pestaña SSH tenga la IP del
failure  o  Connection  antes de intentar la  Host-Only ( .101 / .102 ) usuario
conexión a MariaDB
| refused |     |     |     | bddadmin |  y contraseña correcta  |     |
| ------- | --- | --- | --- | -------- | ------------------------ | --- |
probar primero un cliente SSH
externo (PowerShell) para
descartar problemas de
credenciales SSH
DBeaver muestra  Public Key  El driver JDBC de  En la configuración de conexión
Retrieval is not allowed MariaDB requiere ajuste  de DBeaver pestaña  Driver
|     |     | de parámetros SSL para  |     | properties |  añadir la propiedad  |     |
| --- | --- | ----------------------- | --- | ---------- | ---------------------- | --- |
conexión local
allowPublicKeyRetrieval =
true
El slow query log no registra la  El archivo de  Verificar la sintaxis con
sudo
| consulta        |     | configuración    |         |                             |     |        |
| --------------- | --- | ---------------- | ------- | --------------------------- | --- | ------ |
| SELECT SLEEP(3) |     |                  | 99-lab- | mariadb -e "SHOW VARIABLES  |     |        |
|                 |     |  tiene un error  |         |                             |     |   si  |
|                 |     | logs.cnf         |         | LIKE 'slow_query_log';"     |     |        |
de sintaxis o el servicio
|     |     |     |     | devuelve  | OFF  revisar el archivo  |     |
| --- | --- | --- | --- | --------- | ------------------------- | --- |
no se reinició tras crearlo
|     |     |     |     | de configuración y ejecutar  |     | sudo  |
| --- | --- | --- | --- | ---------------------------- | --- | ----- |
systemctl restart mariadb
scp  falla al copiar los scripts  La clave pública SSH no  Agregar la flag  -o
| de         |  a         | está configurada entre  |     |                                  |     |  al  |
| ---------- | ---------- | ----------------------- | --- | -------------------------------- | --- | ---- |
| bdd-nodo01 | bdd-nodo02 |                         |     | StrictHostKeyChecking=no         |     |      |
|            |            | nodos (se usa           |     |  la primera vez e introducir la  |     |      |
scp
contraseña cuando se solicite
26

|     | autenticación por  |     |     | alternativamente copiar el  |     |     |
| --- | ------------------ | --- | --- | ---------------------------- | --- | --- |
|     | contraseña)        |     |     | contenido del script         |     |     |
manualmente
El conteo de  detalle_pedidos   Alguna clave foránea  Verificar el orden de inserción
da menos de  falló durante la inserción  (primero  clientes  luego
|     | posiblemente porque los    |     |     | productos                         |  luego  pedidos |  por      |
| --- | -------------------------- | --- | --- | --------------------------------- | ---------------- | ---------- |
|     | producto_id                |  o  |     | último  detalle_pedidos           |                  | ) si hay  |
|     | pedido_id                  |     |     | errores de FK truncar todas las  |                  |            |
|     | referenciados no existían  |     |     | tablas (                          | SET              |            |
|     | en ese momento             |     |     | FOREIGN_KEY_CHECKS=0              |                  | ) y        |
reejecutar los scripts en orden
UPDATE pedidos SET total =  El subquery de  Verificar con  SELECT COUNT(*)
...  actualiza  filas detalle_pedidos  no  FROM detalle_pedidos;  si hay
|     | encontró filas porque la  |     |     | filas si no hay repetir la  |                 |     |
| --- | ------------------------- | --- | --- | ----------------------------- | --------------- | --- |
|     | inserción anterior falló  |     |     | inserción de                  | detalle_pedidos |     |
parcialmente
|                             |                       |       |     | antes de ejecutar el         |                    | UPDATE |
| --------------------------- | --------------------- | ----- | --- | ---------------------------- | ------------------ | ------ |
|                             | Error de sintaxis en  |       |     | Revisar el log de arranque  |                    |        |
| systemctl restart mariadb   |                       |       | 99- |                              |                    | sudo   |
| tarda más de  segundos o  |                       |  que  |     |                              |                    |        |
|                             | lab-logs.cnf          |       |     | journalctl -u mariadb --no-  |                    |        |
| falla                       | impide que el motor   |       |     |                              |  buscar la línea  |        |
pager -n 30
|     | arranque |     |     |         |  o               |     |
| --- | -------- | --- | --- | ------- | ---------------- | --- |
|     |          |     |     | [ERROR] | unknown variable |     |
para identificar el parámetro mal
escrito
G. Checklist de validación
SHOW DATABASES;  muestra  lab_bdd  en ambos nodos; no existe  test .
Las cuatro tablas ( clientes ,  productos ,  pedidos ,  detalle_pedidos )
existen en   en ambos nodos con las columnas y tipos correctos.
lab_bdd
Los datos de prueba están insertados: 20 clientes, 10 productos, 20 pedidos,
36 detalles en ambos nodos.
SHOW GRANTS FOR 'lab_admin'@'localhost';  muestra  ALL PRIVILEGES ON lab_bdd.*
en ambos nodos.
SHOW GRANTS FOR 'app_user'@'localhost';  muestra únicamente los privilegios
DML ( SELECT, INSERT, UPDATE, DELETE ) sobre  lab_bdd.*  en ambos nodos.
El intento de ejecutar  DROP TABLE  con  app_user  devuelve  Access denied .
/etc/mysql/mariadb.conf.d/99-lab-logs.cnf  existe en ambos nodos con el
contenido correcto.
SHOW VARIABLES LIKE 'slow_query_log';  devuelve  ON  en ambos nodos.
/var/log/mysql/mariadb-slow.log  contiene la entrada del  SELECT SLEEP(3)
ejecutado durante la verificación, en ambos nodos.
27

Los archivos de respaldo mysqldump existen en /opt/lab_bdd_backups/ con
la línea -- Dump completed on al final, en ambos nodos.
La conexión DBeaver con túnel SSH funciona hacia bdd-nodo01 y bdd-nodo02
y muestra las tablas de lab_bdd .
La consulta de resumen por región ejecutada en D.8 devuelve 4 filas (norte,
sur, este, oeste) con datos de clientes, pedidos e ingresos.
La conectividad Host-Only sigue funcionando: ping 192.168.56.101 y
ping 192.168.56.102 responden desde el host Windows.
Ambas VMs se apagaron de forma ordenada.
Los snapshots fase08-completa existen en bdd-nodo01 y bdd-nodo02 .
Las credenciales de los usuarios creados están documentadas en
C:\LabBDD\Snapshots-Notas\fase08-notas.txt .
Puedo explicar la diferencia entre los plugins unix_socket y
mysql_native_password y cuándo se usa cada uno.
Puedo explicar por qué el esquema lab_bdd fue diseñado con el campo
region y la separación entre columnas básicas y de detalle en productos .
Preguntas teóricas para estudiantes
 MariaDB identifica a los usuarios mediante el par usuario@host en lugar de solo
por el nombre de usuario Explica qué implicación tiene esto en el modelo de
seguridad ¿puede existir un usuario app_user@'localhost' y al mismo tiempo
un app_user@'192.168.56.%' con privilegios totalmente distintos? ¿En qué
escenario de este laboratorio sería relevante esa diferencia?
 Describe el flujo completo de una conexión DBeaver al motor MariaDB usando
túnel SSH: ¿qué componentes participan en qué orden establecen la comunicación
y por qué el motor de MariaDB solo ve conexiones provenientes de 127.0.0.1 a
pesar de que DBeaver está en una máquina diferente?
 ¿Qué diferencia hay entre mysqldump --single-transaction y un respaldo sin
esa opción? ¿Por qué es importante la opción --single-transaction para bases
de datos InnoDB y en qué situación no sería suficiente para garantizar
consistencia?
 El diseño de la tabla pedidos incluye una columna region que duplica
(de forma controlada) la región del cliente asociado Discute las ventajas y
desventajas de esta redundancia desde la perspectiva de la fragmentación
horizontal planeada para la Fase  ¿Qué problema resuelve esta redundancia
al momento de fragmentar?
28

 El slow query log se configuró con long_query_time = 2  Explica qué
criterios se usarían para elegir un umbral más bajo (por ejemplo  segundos)
o más alto (por ejemplo  segundos) en un sistema real y qué consecuencias
tiene sobre el tamaño del log y el rendimiento del servidor cada elección
Ejercicios prácticos
 Exploración de metadatos con information_schema 
Escribir una consulta SQL que liste para cada tabla de lab_bdd  el nombre
de cada columna su tipo de dato si admite NULL si tiene valor por defecto
y si forma parte de una clave primaria o foránea La consulta debe usar
information_schema.COLUMNS y information_schema.KEY_COLUMN_USAGE con un
JOIN  y ordenar el resultado por tabla y por posición de columna Ejecutarla
dentro de sudo mariadb y documentar los resultados
 Verificación de integridad del respaldo
Crear una base de datos temporal lab_bdd_test en bdd-nodo01  restaurar
el respaldo generado con mysqldump usando mariadb lab_bdd_test < archivo.sql 
y ejecutar la misma consulta de conteo de registros en ambas bases de datos
( lab_bdd y lab_bdd_test ) para confirmar que los datos son idénticos Al
finalizar eliminar lab_bdd_test con DROP DATABASE 
 Análisis del slow query log
Habilitar temporalmente log_queries_not_using_indexes = 1 en
99-lab-logs.cnf  reiniciar MariaDB y ejecutar cinco consultas variadas sobre
lab_bdd (al menos dos sin cláusula WHERE con índice dos con JOIN entre
tablas y una con GROUP BY ) Revisar el slow query log con sudo tail -50
/var/log/mysql/mariadb-slow.log e identificar cuáles consultas aparecen y por
qué Restaurar el valor original ( log_queries_not_using_indexes = 0 ) al
finalizar
Reto adicional para alumnos avanzados
Implementar un script de respaldo automatizado en Bash que: (a) genere un
mysqldump de lab_bdd con fecha y hora en el nombre del archivo,
(b) comprima el resultado con gzip , © elimine automáticamente los respaldos
con más de 7 días de antigüedad para evitar llenar el disco, y (d) registre en un
archivo de log propio ( /opt/lab_bdd_backups/backup.log ) la fecha, hora, tamaño
del archivo generado y si el proceso fue exitoso o no. El script debe poder
29

ejecutarse manualmente y también estar preparado para ser invocado por cron .
Incluir en la entrega el script comentado y la entrada de crontab sugerida
para ejecutarlo diariamente a las 02:00 AM.
Criterios de evaluación para el profesor
Criterio Peso Indicador de logro
Creación correcta del % Las cuatro tablas existen en ambos nodos con
esquema lab_bdd los tipos de dato correctos claves foráneas
definidas y comentarios que identifican el rol
de cada tabla en la distribución futura
Gestión de usuarios y % lab_admin y app_user existen con
privilegios exactamente los privilegios descritos se
demuestra que app_user no puede ejecutar
DDL
Configuración y verificación % 99-lab-logs.cnf existe y está correcto
de logs SHOW VARIABLES confirma el slow log activo
el log muestra al menos una entrada de la
consulta de prueba
Respaldo con mysqldump % Se generaron los dos tipos de respaldo (solo
DDL y completo) el alumno puede explicar la
diferencia entre ambos y el propósito de --
single-transaction
Conexión remota con % DBeaver conecta exitosamente a ambos
DBeaver y túnel SSH nodos sin errores el alumno puede explicar
por qué se usa un túnel en lugar de abrir
directamente el puerto 
Comprensión conceptual % Responde correctamente las preguntas  a
(preguntas teóricas)  usando vocabulario técnico apropiado y
haciendo referencia al contexto específico
del laboratorio
Preparación para la siguiente fase
La Fase 9: Diseño de la Arquitectura Distribuida requerirá:
• El esquema lab_bdd idéntico en bdd-nodo01 y bdd-nodo02 (esta fase)
• Snapshot fase08-completa tomado en ambas VMs
30

• Comprensión del diseño del esquema por qué cada tabla tiene los campos que
tiene y cómo se mapean a estrategias de fragmentación futuras
• Acceso SSH y DBeaver funcionando (para consultar y documentar el esquema
durante la fase de diseño)
La Fase 9 no instalará ni configurará nada nuevo en las VMs: será una fase
teórico-analítica en la que se tomará el esquema lab_bdd ya existente y se
diseñará, sobre papel y diagramas, el plan de distribución completo que se
implementará en las Fases 10 a 16.
31

Fase 9 — Diseño de la Arquitectura Distribuida
MGTI. Baltazar Martinez Galla
Continuación directa de la Fase 8. Ambos nodos tienen MariaDB 10.11 instalado
con el esquema lab_bdd poblado con datos de prueba y snapshot fase08-completa
tomado. Esta fase no instala ni configura nada nuevo en las máquinas virtuales:
es una fase de análisis y diseño en la que se toma el esquema centralizado existente
y se elabora el plan completo de distribución que se implementará en las Fases 10
a 16. El principal entregable es el Documento de Diseño Distribuido (DDD),
que servirá como referencia técnica en todas las fases posteriores.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Aplicar la metodología top-down de diseño de bases de datos distribuidas para
traducir un esquema relacional centralizado en un plan de distribución formal
 Distinguir y construir los tres esquemas del diseño distribuido esquema global
esquema de fragmentación y esquema de asignación
 Definir fragmentos horizontales mediante predicados simples y combinaciones de
predicados minterm verificando su correctitud (completitud disjunción y
reconstrucción)
 Definir fragmentos verticales usando el criterio de afinidad de columnas y
verificar su correctitud (completitud y reconstrucción mediante JOIN sobre la PK)
 Diseñar la estrategia de fragmentación híbrida que emerge de la combinación de
las fragmentaciones horizontal y vertical sobre distintas tablas del mismo esquema
 Justificar las decisiones de asignación de datos a nodos específicos usando
criterios de localidad de acceso balanceo de carga y co-localización de tablas
relacionadas por claves foráneas
 Elaborar la matriz de asignación completa del laboratorio especificando para
cada fragmento el nodo destino y la fase de implementación
 Escribir y ejecutar consultas SQL que simulen en el nodo centralizado actual las
operaciones de reconstrucción que el sistema distribuido realizará en fases
posteriores verificando que producen resultados correctos
 Producir el Documento de Diseño Distribuido ( fase09-disenyo-distribuido.md )
que actuará como especificación técnica de referencia para las Fases  a 
1

B. Conceptos teóricos necesarios
1. Metodología top-down de diseño de BDD.
El diseño de una base de datos distribuida puede abordarse de dos formas:
• Top-down se parte de los requisitos globales se diseña el esquema centralizado
y después se decide cómo distribuirlo Es el enfoque de este laboratorio el esquema
lab_bdd ya existe como punto de partida centralizado y se redistribuirá
• Bottom-up se integran esquemas preexistentes en distintos nodos en un esquema
global unificado Se usa cuando los datos ya existen en múltiples sistemas heredados
El proceso top-down involucra tres fases de diseño, que se desarrollan en esta fase
del laboratorio:
2. Fragmentación horizontal.
Una fragmentación horizontal divide las filas de una relación R en subconjuntos
llamados fragmentos R₁, R₂, ..., Rₙ , cada uno definido por un predicado de selección:
Text
Rᵢ = σ(predicado_i)(R)
• Predicado simple condición sobre un único atributo por ejemplo region = 'norte' 
2

• Predicado minterm combinación booleana completa de todos los predicados simples
relevantes Si hay n predicados simples p₁, p₂, ..., pₙ  existen hasta 2ⁿ
minterms posibles solo los minterms no vacíos generan fragmentos reales
Para region con cuatro valores distintos, los predicados simples son p₁: region =
'norte' , p₂: region = 'sur' , p₃: region = 'este' , p₄: region = 'oeste' . Este
laboratorio los agrupa en dos fragmentos de dos minterms cada uno, por limitación de
nodos de sharding disponibles (dos: nodo04 y nodo05).
3. Condiciones de correctitud de la fragmentación.
Toda fragmentación debe cumplir tres condiciones para ser válida:
• Completitud (completeness) ∀t ∈ R, ∃i tal que t ∈ Rᵢ  Ninguna fila puede
perderse toda tupla de la relación global debe aparecer en al menos un fragmento
• Disjunción (disjointness) ∀i ≠ j, Rᵢ ∩ Rⱼ = ∅  En fragmentación
horizontal ninguna fila debe pertenecer a más de un fragmento En fragmentación
vertical las columnas no clave no deben repetirse (la PK sí se duplica y es
obligatorio hacerlo para la reconstrucción)
• Reconstrucción (reconstruction) la relación global puede obtenerse a partir
de sus fragmentos — mediante UNION ALL para fragmentación horizontal o mediante
JOIN sobre la PK para fragmentación vertical
4. Fragmentación vertical.
Una fragmentación vertical divide las columnas de una relación R . Formalmente:
Text
Vᵢ = π(Cᵢ ∪ {PK})(R)
Cada fragmento proyecta un subconjunto de columnas Cᵢ , más la clave primaria,
que siempre debe estar presente en todos los fragmentos para permitir la reconstrucción
por JOIN. Los conjuntos de columnas no clave deben ser disjuntos: Cᵢ ∩ Cⱼ = ∅
para todo i ≠ j .
La técnica de afinidad de columnas estima qué tan frecuentemente se acceden
conjuntamente dos columnas. Las de alta afinidad entre sí se agrupan en el mismo
fragmento. En la práctica del laboratorio se usa el criterio de patrón de uso:
columnas que aparecen en consultas frecuentes (listados, búsquedas, cálculo de precios)
se separan de columnas de descripción extensa/TEXT consultadas solo en pantallas de
detalle.
3

5. Fragmentación híbrida.
La fragmentación híbrida combina ambas estrategias sobre el mismo esquema. En este
laboratorio surge de forma natural: clientes , pedidos y detalle_pedidos se
fragmentan horizontalmente por región (Fase 13), mientras que productos se
fragmenta verticalmente por grupos de columnas (Fase 14). Las consultas que
combinan ambas tablas en un mismo resultado (Fase 15) cruzan los dos tipos de
fragmentación, constituyendo el escenario híbrido sin necesidad de introducir una
tercera tabla de ejemplo.
6. Estrategias de asignación de datos.
Una vez definidos los fragmentos, se decide en qué nodo(s) reside cada uno:
• Particionada cada fragmento existe en exactamente un nodo Maximiza el uso del
espacio disponible la caída de un nodo hace inaccesibles sus fragmentos
• Replicada el fragmento (o la relación completa) se copia en varios nodos Mejora
disponibilidad y rendimiento de lectura complica las escrituras (consistencia)
• Híbrida algunos fragmentos son particionados y otros son replicados
Este laboratorio usa el modelo híbrido: lab_bdd completa se replica entre nodo01
y nodo02 (Fase 10, replicación física), y sobre los nodos 04 y 05 se aplica
particionamiento horizontal de algunas tablas (Fase 13).
7. Co-localización de tablas relacionadas.
Cuando dos tablas se unen frecuentemente mediante JOIN (como pedidos y
detalle_pedidos ), y ambas se van a fragmentar horizontalmente, la decisión de
co-localizar sus fragmentos en el mismo nodo elimina los joins remotos entre nodos,
que son la operación más costosa en un sistema distribuido (transferencia de datos por
red). La regla práctica es: si existe una clave foránea entre dos tablas y la tabla
hija puede fragmentarse derivadamente por el mismo predicado de la tabla padre, deben
co-localizarse en el mismo nodo.
8. El nodo coordinador y el motor Spider.
En un sistema distribuido, algún nodo debe actuar como coordinador de consultas
globales: recibe las consultas del cliente, las descompone en subconsultas dirigidas
a los nodos con los fragmentos relevantes, recibe los resultados parciales y los
combina en la respuesta final. En este laboratorio, bdd-nodo06 desempeñará ese rol
mediante el motor Spider de MariaDB — un motor de almacenamiento nativo de MariaDB
que actúa como tabla puente hacia tablas remotas en otros servidores MariaDB. Desde el
punto de vista del cliente, Spider hace que las tablas distribuidas en nodo04/nodo05
aparezcan como tablas locales en nodo06, implementando así la transparencia de
fragmentación y ubicación.
4

C. Procedimiento paso a paso
Paso 1 — Iniciar bdd-nodo01 y conectarse por SSH.
Solo se necesita un nodo para el análisis; ambos tienen el mismo esquema y datos.
Paso 2 — Ejecutar el análisis estadístico de lab_bdd .
Recopilar métricas de distribución de datos y de tamaño de columnas que justificarán
cada decisión de diseño con evidencia cuantitativa (sección D.2).
Paso 3 — Diseñar y verificar la fragmentación horizontal.
Definir los predicados de los dos fragmentos de clientes , pedidos y
detalle_pedidos ; ejecutar las consultas de verificación de completitud, disjunción
y reconstrucción sobre los datos reales (sección D.3).
Paso 4 — Diseñar y verificar la fragmentación vertical de productos .
Definir los dos grupos de columnas, justificar la agrupación según el patrón de uso
esperado y ejecutar la verificación de correctitud (sección D.4).
Paso 5 — Simular las consultas distribuidas en el entorno centralizado.
Escribir las cuatro consultas que en las Fases 13–16 el coordinador ejecutará de forma
distribuida y ejecutarlas localmente para confirmar que producen resultados correctos
antes de dispersar los datos (sección D.5).
Paso 6 — Revisar la topología de replicación.
Generar el diagrama de texto de la topología completa del laboratorio dentro del nodo,
que se trasladará al documento de diseño (sección D.6).
Paso 7 — Generar la matriz de asignación completa.
Visualizar como consulta SQL la tabla que relaciona cada fragmento con su nodo destino,
su IP y su fase de implementación (sección D.7).
Paso 8 — Crear el Documento de Diseño Distribuido en el host.
Generar el archivo C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md que
consolida el diseño completo y servirá como referencia obligatoria en las Fases 10–16
(sección D.8).
Paso 9 — Apagar la VM y tomar el snapshot de cierre de fase.
Aunque no hubo cambios en el sistema operativo ni en el motor, el snapshot marca el
estado verificado del laboratorio en el punto en que el diseño fue completado (D.9).
5

D. Comandos completos
Los comandos marcados (VM) se ejecutan en una sesión SSH en bdd-nodo01 . Los
marcados (host) se ejecutan en PowerShell en Windows. Los bloques iniciados con
sudo mariadb se ejecutan dentro del prompt del motor.
D.1 Iniciar bdd-nodo01 y conectarse (host)
PowerShell
VBoxManage startvm "bdd-nodo01" --type headless
Esperar 20–30 segundos y conectarse:
PowerShell
ssh bddadmin@192.168.56.101
6

D.2 Análisis estadístico del esquema lab_bdd (VM)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- BLOQUE 1: Estructura del esquema global
-- ============================================================
-- Tablas, motor y tamaño aproximado
SELECT TABLE_NAME AS tabla,
ENGINE AS motor,
TABLE_ROWS AS filas_aprox,
ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024.0, 1) AS total_KB
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'lab_bdd'
ORDER BY DATA_LENGTH DESC;
-- Columnas por tabla (base para decisiones de fragmentación vertical)
SELECT TABLE_NAME AS tabla,
COLUMN_NAME AS columna,
ORDINAL_POSITION AS pos,
DATA_TYPE AS tipo,
CHARACTER_MAXIMUM_LENGTH AS max_chars,
IS_NULLABLE AS nulable,
COLUMN_KEY AS clave
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'lab_bdd'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
-- Restricciones de clave foránea (determinan co-localización obligatoria)
SELECT CONSTRAINT_NAME AS restriccion,
TABLE_NAME AS tabla_hijo,
COLUMN_NAME AS columna_hijo,
REFERENCED_TABLE_NAME AS tabla_padre,
REFERENCED_COLUMN_NAME AS columna_padre
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'lab_bdd'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- ============================================================
-- BLOQUE 2: Distribución del atributo de fragmentación
-- ============================================================
-- Distribución de clientes por región (atributo candidato
a fragmentación)
SELECT region,
COUNT(*) AS num_clientes,
ROUND(COUNT(*) * 100.0 / 20, 1) AS pct_del_total,
GROUP_CONCAT(ciudad ORDER BY ciudad) AS ciudades
FROM clientes
GROUP BY region
7

ORDER BY region;
-- Distribución de pedidos por región y estado
SELECT region,
COUNT(*) AS num_pedidos,
ROUND(SUM(total), 2) AS ingresos
FROM pedidos
GROUP BY region
ORDER BY region;
-- Líneas de detalle co-localizables con cada fragmento de pedidos
SELECT p.region,
COUNT(DISTINCT p.id) AS pedidos,
COUNT(dp.id) AS lineas_detalle,
ROUND(SUM(dp.subtotal), 2) AS facturacion
FROM pedidos p
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
GROUP BY p.region
ORDER BY p.region;
-- ============================================================
-- BLOQUE 3: Análisis de columnas de 'productos'
-- (candidatas a fragmentación vertical)
-- ============================================================
-- Longitud promedio por columna de tipo texto (identifica las "pesadas")
SELECT 'sku' AS columna, ROUND(AVG(LENGTH(sku)), 1) AS
bytes_prom FROM productos UNION ALL
SELECT 'nombre', ROUND(AVG(LENGTH(nombre)), 1)
FROM productos UNION ALL
SELECT 'categoria', ROUND(AVG(LENGTH(categoria)), 1)
FROM productos UNION ALL
SELECT 'descripcion', ROUND(AVG(LENGTH(descripcion)), 1)
FROM productos UNION ALL
SELECT 'ficha_tecnica', ROUND(AVG(LENGTH(ficha_tecnica)), 1)
FROM productos UNION ALL
SELECT 'imagen_url', ROUND(AVG(LENGTH(imagen_url)), 1)
FROM productos;
EOF
Registrar los resultados de los tres bloques. Estos datos son la evidencia
cuantitativa que respalda cada decisión de diseño en los pasos siguientes.
8

D.3 Fragmentación horizontal — definición y verificación de
correctitud (VM)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- DEFINICIÓN DE FRAGMENTOS HORIZONTALES
-- ============================================================
-- Atributo de fragmentación: region ENUM('norte','sur','este','oeste')
-- Número de fragmentos: 2 (limitado a los nodos de sharding disponibles)
--
-- frag_A → bdd-nodo04 (192.168.56.104): region IN ('norte', 'este')
-- frag_B → bdd-nodo05 (192.168.56.105): region IN ('sur', 'oeste')
--
-- Justificación del agrupamiento: 5 clientes por valor de región
-- (datos uniformes) → ambos fragmentos tendrán 10 filas de clientes,
-- produciendo un balanceo de carga perfecto.
-- ============================================================
-- ---------- Vista de cada fragmento ----------
SELECT 'clientes_frag_A (norte+este)' AS fragmento,
COUNT(*) AS filas,
GROUP_CONCAT(DISTINCT region) AS regiones_incluidas
FROM clientes WHERE region IN ('norte', 'este');
SELECT 'clientes_frag_B (sur+oeste)' AS fragmento,
COUNT(*) AS filas,
GROUP_CONCAT(DISTINCT region) AS regiones_incluidas
FROM clientes WHERE region IN ('sur', 'oeste');
-- ---------- VERIFICACIÓN DE CORRECTITUD — CLIENTES ----------
-- 1. COMPLETITUD: suma de fragmentos debe igualar el total global
SELECT 'Completitud clientes' AS condicion,
(SELECT COUNT(*) FROM clientes) AS total_global,
(SELECT COUNT(*) FROM clientes WHERE region IN ('norte','este')) +
(SELECT COUNT(*) FROM clientes WHERE region IN ('sur','oeste'))
AS suma_fragmentos,
CASE
WHEN (SELECT COUNT(*) FROM clientes) =
(SELECT COUNT(*) FROM clientes WHERE region IN
('norte','este')) +
(SELECT COUNT(*) FROM clientes WHERE region
IN ('sur','oeste'))
THEN 'OK' ELSE 'FALLA'
END AS resultado;
-- 2. DISJUNCIÓN: ninguna fila puede pertenecer a ambos fragmentos
-- (se verifica buscando filas cuyo valor de region satisfaga
-- simultáneamente los dos predicados; debe devolver 0)
SELECT 'Disjunción clientes' AS condicion,
COUNT(*) AS
9

filas_en_interseccion,
CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FALLA' END AS resultado
FROM clientes
WHERE region IN ('norte','este') AND region IN ('sur','oeste');
-- 3. RECONSTRUCCIÓN: UNION ALL de fragmentos produce la relación global
SELECT 'Reconstrucción clientes' AS condicion,
(SELECT COUNT(*) FROM clientes) AS filas_globales,
COUNT(*) AS filas_reconstruidas,
CASE
WHEN (SELECT COUNT(*) FROM clientes) = COUNT(*)
THEN 'OK' ELSE 'FALLA'
END AS resultado
FROM (
SELECT * FROM clientes WHERE region IN ('norte', 'este')
UNION ALL
SELECT * FROM clientes WHERE region IN ('sur', 'oeste')
) AS reconstruccion;
-- ---------- VERIFICACIÓN CONDENSADA — PEDIDOS ----------
SELECT 'Completitud pedidos' AS condicion,
CASE
WHEN (SELECT COUNT(*) FROM pedidos) =
(SELECT COUNT(*) FROM pedidos WHERE region IN
('norte','este')) +
(SELECT COUNT(*) FROM pedidos WHERE region
IN ('sur','oeste'))
THEN 'OK' ELSE 'FALLA'
END AS resultado
UNION ALL
SELECT 'Disjunción pedidos',
CASE WHEN
(SELECT COUNT(*) FROM pedidos
WHERE region IN ('norte','este') AND region IN ('sur','oeste'))
= 0
THEN 'OK' ELSE 'FALLA' END
UNION ALL
SELECT 'Reconstrucción pedidos',
CASE WHEN (SELECT COUNT(*) FROM pedidos) =
(SELECT COUNT(*) FROM pedidos WHERE region IN
('norte','este')) +
(SELECT COUNT(*) FROM pedidos WHERE region
IN ('sur','oeste'))
THEN 'OK' ELSE 'FALLA' END;
-- ---------- DETALLE_PEDIDOS: fragmentación derivada ----------
-- detalle_pedidos no tiene columna 'region' propia; se fragmenta
-- siguiendo al pedido al que pertenece (co-localización obligatoria
-- por la FK pedido_id → pedidos.id que impide joins remotos).
SELECT 'detalle_frag_A (pedidos norte+este)' AS fragmento,
COUNT(*) AS filas
10

FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('norte', 'este');
SELECT 'detalle_frag_B (pedidos sur+oeste)' AS fragmento,
COUNT(*) AS filas
FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('sur', 'oeste');
-- Verificación de completitud de la fragmentación derivada
SELECT 'Completitud detalle_pedidos' AS
condicion,
(SELECT COUNT(*) FROM detalle_pedidos)
AS total_global,
(SELECT COUNT(*) FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('norte','este')) +
(SELECT COUNT(*) FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('sur','oeste')) AS
suma_fragmentos,
CASE
WHEN (SELECT COUNT(*) FROM detalle_pedidos) =
(SELECT COUNT(*) FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('norte','este')) +
(SELECT COUNT(*) FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
WHERE p.region IN ('sur','oeste'))
THEN 'OK' ELSE 'FALLA'
END AS resultado;
EOF
11

D.4 Fragmentación vertical de productos — definición y verificación (VM)
Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- DEFINICIÓN DE FRAGMENTOS VERTICALES
-- ============================================================
-- Tabla fuente: productos (10 columnas de datos + PK 'id')
--
-- Criterio de agrupación: patrón de uso esperado
-- COLUMNAS OPERACIONALES (consulta frecuente):
-- id*, sku, nombre, categoria, precio, stock, fecha_creacion
-- → aparecen en listados, búsquedas y cálculos de precios
-- → Fragmento V_basico → bdd-nodo04 (192.168.56.104)
--
-- COLUMNAS DE DETALLE (consulta poco frecuente, volumen alto):
-- id*, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
-- → aparecen solo al consultar la ficha completa de un producto
-- → Columnas TEXT: promedio de 60-170 bytes/fila (análisis D.2)
-- → Fragmento V_detalle → bdd-nodo05 (192.168.56.105)
--
-- Nota: 'id' (PK) se duplica en ambos fragmentos para reconstrucción
-- por JOIN. 'sku' (clave alternativa) también se duplica por
-- ser referencia natural de negocio usada en ambos contextos;
-- esto es una decisión de diseño deliberada, no una violación
-- de la disjunción (que aplica a columnas NO CLAVE).
-- ============================================================
-- Vista previa del fragmento básico (7 columnas)
SELECT id, sku, nombre, categoria, precio, stock, fecha_creacion
FROM productos
ORDER BY id;
-- Vista previa del fragmento detalle (6 columnas)
SELECT id, sku,
SUBSTRING(descripcion, 1, 45) AS descripcion_preview,
SUBSTRING(ficha_tecnica, 1, 45) AS ficha_preview,
imagen_url,
peso_kg
FROM productos
ORDER BY id;
-- ---- VERIFICACIÓN DE CORRECTITUD — VERTICAL ----
-- 1. COMPLETITUD: todos los productos deben estar en ambos fragmentos
SELECT 'Completitud V_basico' AS condicion,
(SELECT COUNT(*) FROM productos) AS total_global,
COUNT(*) AS
filas_en_fragmento,
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA' END AS resultado
12

FROM (SELECT id, sku, nombre, categoria, precio, stock, fecha_creacion
FROM productos) AS frag_basico
UNION ALL
SELECT 'Completitud V_detalle',
(SELECT COUNT(*) FROM productos),
COUNT(*),
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA' END
FROM (SELECT id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos) AS frag_detalle;
-- 2. DISJUNCIÓN DE COLUMNAS NO CLAVE
-- V_basico (no clave): nombre, categoria, precio,
stock, fecha_creacion
-- V_detalle (no clave): descripcion, ficha_tecnica,
imagen_url, peso_kg
-- Intersección = vacío → condición cumplida
SELECT 'Disjunción de columnas no clave' AS condicion,
'nombre, categoria, precio, stock, fecha_creacion'
AS cols_V_basico,
'descripcion, ficha_tecnica, imagen_url, peso_kg'
AS cols_V_detalle,
'Sin superposición (OK)' AS resultado;
-- 3. RECONSTRUCCIÓN: JOIN por PK reconstituye la relación completa
SELECT 'Reconstrucción productos (JOIN en id)' AS condicion,
(SELECT COUNT(*) FROM productos) AS filas_globales,
COUNT(*) AS
filas_reconstruidas,
CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM productos)
THEN 'OK' ELSE 'FALLA' END AS resultado
FROM (
SELECT b.id, b.sku, b.nombre, b.categoria, b.precio, b.stock,
d.descripcion, d.ficha_tecnica, d.imagen_url, d.peso_kg,
b.fecha_creacion
FROM (SELECT id, sku, nombre, categoria, precio,
stock, fecha_creacion
FROM productos) b
JOIN (SELECT id, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
FROM productos) d ON b.id = d.id
) AS reconstruccion;
-- Verificación visual: primer registro reconstruido vs. original
SELECT 'Original' AS origen, id, sku, nombre, precio,
SUBSTRING(descripcion, 1, 35) AS desc_preview
FROM productos WHERE id = 1
UNION ALL
SELECT 'Reconstruido' AS origen, b.id, b.sku, b.nombre, b.precio,
SUBSTRING(d.descripcion, 1, 35)
FROM (SELECT id, sku, nombre, precio FROM productos WHERE id = 1) b
JOIN (SELECT id, descripcion FROM productos WHERE id = 1) d ON
13

b.id = d.id;
EOF
D.5 Simulación de consultas distribuidas en el entorno centralizado (VM)
Estas consultas representan las operaciones que bdd-nodo06 (coordinador) ejecutará
en las Fases 14–16 mediante el motor Spider. Ejecutarlas ahora — cuando todos los
datos conviven en bdd-nodo01 — permite verificar que los resultados esperados son
correctos antes de dispersar los datos entre nodos.
14

Bash
sudo mariadb lab_bdd << 'EOF'
-- ============================================================
-- CONSULTA DISTRIBUIDA 1 — Pedidos con datos de cliente
-- Fragmentos: clientes_frag_A + pedidos_frag_A (nodo04)
-- clientes_frag_B + pedidos_frag_B (nodo05)
-- El coordinador envía la subconsulta a cada shard y hace
-- UNION ALL del resultado. No hay transferencia de datos entre
-- nodo04 y nodo05 porque los fragmentos de clientes y pedidos
-- están co-localizados por región.
-- ============================================================
SELECT c.region,
CONCAT(c.nombre, ' ', c.apellido) AS cliente,
p.id AS pedido_id,
p.estado,
p.total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
WHERE c.region IN ('norte', 'este') -- → subconsulta a nodo04
UNION ALL
SELECT c.region,
CONCAT(c.nombre, ' ', c.apellido),
p.id, p.estado, p.total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
WHERE c.region IN ('sur', 'oeste') -- → subconsulta a nodo05
ORDER BY region, pedido_id;
-- ============================================================
-- CONSULTA DISTRIBUIDA 2 — Líneas de pedido con nombre de producto
-- Fragmentos: pedidos_frag_* (nodo04/05) + V_basico (nodo04)
-- Solo se necesita el fragmento básico de productos (precio y nombre);
-- V_detalle (nodo05) no interviene → el coordinador evita un join
-- innecesario al nodo que contiene columnas TEXT.
-- ============================================================
SELECT p.region,
p.id AS pedido_id,
pr.nombre AS producto,
pr.categoria,
dp.cantidad,
dp.precio_unitario AS precio_vendido,
dp.subtotal
FROM detalle_pedidos dp
JOIN pedidos p ON p.id = dp.pedido_id
JOIN productos pr ON pr.id = dp.producto_id
ORDER BY p.region, p.id;
-- ============================================================
-- CONSULTA DISTRIBUIDA 3 — Ficha completa de un producto
15

-- Fragmentos: V_basico (nodo04) + V_detalle (nodo05)
-- El coordinador hace JOIN entre los dos fragmentos verticales
-- para reconstruir la fila completa. Solo se activa cuando el
-- usuario necesita ver la descripción y ficha técnica.
-- ============================================================
SELECT b.id, b.sku, b.nombre, b.categoria,
b.precio, b.stock,
d.descripcion,
d.ficha_tecnica,
d.peso_kg
FROM (SELECT id, sku, nombre, categoria, precio, stock
FROM productos WHERE id = 1) b
JOIN (SELECT id, descripcion, ficha_tecnica, peso_kg
FROM productos WHERE id = 1) d ON b.id = d.id;
-- ============================================================
-- CONSULTA DISTRIBUIDA 4 — Híbrida: ventas por región con
-- categorías de productos (cruza fragmentación horizontal de
-- clientes/pedidos y fragmentación vertical de productos)
-- ============================================================
SELECT c.region,
COUNT(DISTINCT c.id) AS clientes_activos,
COUNT(DISTINCT p.id) AS pedidos,
GROUP_CONCAT(DISTINCT pr.categoria
ORDER BY pr.categoria) AS categorias_compradas,
ROUND(SUM(dp.subtotal), 2) AS facturacion_total
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
JOIN detalle_pedidos dp ON dp.pedido_id = p.id
JOIN productos pr ON pr.id = dp.producto_id
GROUP BY c.region
ORDER BY facturacion_total DESC;
-- ============================================================
-- RESUMEN: métricas que el diseño debe conservar íntegras
-- ============================================================
SELECT 'clientes total' AS metrica, COUNT(*) AS valor FROM clientes
UNION ALL
SELECT 'clientes frag_A', COUNT(*) FROM clientes
WHERE region IN ('norte','este') UNION ALL
SELECT 'clientes frag_B', COUNT(*) FROM clientes
WHERE region IN ('sur','oeste') UNION ALL
SELECT 'pedidos total', COUNT(*) FROM pedidos
UNION ALL
SELECT 'pedidos frag_A', COUNT(*) FROM pedidos
WHERE region IN ('norte','este') UNION ALL
SELECT 'pedidos frag_B', COUNT(*) FROM pedidos
WHERE region IN ('sur','oeste') UNION ALL
SELECT 'detalle total', COUNT(*) FROM
detalle_pedidos UNION ALL
16

SELECT 'productos total (V_basico)', COUNT(*) FROM productos
UNION ALL
SELECT 'productos total (V_detalle)', COUNT(*)
FROM productos;
EOF
17

D.6 Diagrama de topología de replicación (VM — referencia para el DDD)
Bash
cat > /tmp/topologia_lab_bdd.txt << 'EOF'
=================================================================
TOPOLOGÍA COMPLETA DEL LABORATORIO BDD — REFERENCIA FASE 9
=================================================================
REPLICACIÓN FÍSICA — Fase 10
─────────────────────────────
bdd-nodo01 [MAESTRO | 192.168.56.101]
lab_bdd (esquema completo)
Binary log activo, GTID habilitado
Acepta lecturas Y escrituras
│
│ binlog stream (row-based, GTID)
▼
bdd-nodo02 [ESCLAVO | 192.168.56.102]
lab_bdd (réplica completa, solo lectura)
read_only = ON
REPLICACIÓN LÓGICA / MULTI-MAESTRO — Fase 11
──────────────────────────────────────────────
bdd-nodo03 [MULTI-MAESTRO | 192.168.56.103]
lab_bdd (réplica completa)
Acepta lecturas Y escrituras
Replicación bidireccional con nodo01
FRAGMENTACIÓN HORIZONTAL — Fase 13
────────────────────────────────────
bdd-nodo04 [SHARD-A | 192.168.56.104]
clientes WHERE region IN ('norte','este') → 10 filas
pedidos WHERE region IN ('norte','este') → 10 filas
detalle_pedidos co-localizado con pedidos_frag_A → ~18 filas
bdd-nodo05 [SHARD-B | 192.168.56.105]
clientes WHERE region IN ('sur','oeste') → 10 filas
pedidos WHERE region IN ('sur','oeste') → 10 filas
detalle_pedidos co-localizado con pedidos_frag_B → ~18 filas
FRAGMENTACIÓN VERTICAL — Fase 14
──────────────────────────────────
bdd-nodo04: V_productos_basico
Columnas: id*, sku, nombre, categoria, precio, stock, fecha_creacion
bdd-nodo05: V_productos_detalle
Columnas: id*, sku, descripcion, ficha_tecnica, imagen_url, peso_kg
COORDINADOR DE CONSULTAS DISTRIBUIDAS — Fases 14-16
─────────────────────────────────────────────────────
bdd-nodo06 [COORDINADOR | 192.168.56.106]
Motor Spider habilitado
Tablas tipo SPIDER apuntando a nodo04 y nodo05
Recibe consultas globales del cliente, las descompone
18

y combina resultados (no almacena datos de lab_bdd)
CLIENTE EXTERNO (opcional) — Fases 16-17
──────────────────────────────────────────
bdd-cliente [192.168.56.107]
Conecta solo a nodo06 (ignora la topología interna)
Prueba de transparencia de distribución
=================================================================
EOF
cat /tmp/topologia_lab_bdd.txt
19

D.7 Matriz de asignación completa (VM — visualización SQL)
Bash
sudo mariadb << 'EOF'
-- Tabla virtual de referencia: matriz de asignación del laboratorio
SELECT fragmento, tabla_origen, tipo_frag,
predicado_o_columnas, nodo_destino, ip_destino, fase
FROM (
SELECT 'lab_bdd_completa (maestro)' AS fragmento,
'todas' AS tabla_origen,
'REPLICADA' AS tipo_frag,
'esquema completo' AS predicado_o_columnas,
'bdd-nodo01' AS nodo_destino,
'192.168.56.101' AS ip_destino,
'10' AS fase
UNION ALL SELECT 'lab_bdd_completa (esclavo)','todas','REPLICADA',
'esquema completo','bdd-nodo02','192.168.56.102','10'
UNION ALL SELECT 'lab_bdd_multimaestro','todas','REPLICADA',
'esquema completo','bdd-nodo03','192.168.56.103','11'
UNION ALL SELECT 'clientes_frag_A','clientes','HORIZONTAL',
"region IN ('norte','este')",'bdd-nodo04','192.168.56.104','13'
UNION ALL SELECT 'clientes_frag_B','clientes','HORIZONTAL',
"region IN ('sur','oeste')",'bdd-nodo05','192.168.56.105','13'
UNION ALL SELECT 'pedidos_frag_A','pedidos','HORIZONTAL',
"region IN ('norte','este')",'bdd-nodo04','192.168.56.104','13'
UNION ALL SELECT 'pedidos_frag_B','pedidos','HORIZONTAL',
"region IN ('sur','oeste')",'bdd-nodo05','192.168.56.105','13'
UNION ALL SELECT 'detalle_frag_A','detalle_pedidos','HORIZONTAL
(derivada)',
'JOIN pedidos frag_A','bdd-nodo04','192.168.56.104','13'
UNION ALL SELECT 'detalle_frag_B','detalle_pedidos','HORIZONTAL
(derivada)',
'JOIN pedidos frag_B','bdd-nodo05','192.168.56.105','13'
UNION ALL SELECT 'V_productos_basico','productos','VERTICAL',
'id,sku,nombre,categoria,precio,stock,fecha_crea','bdd-
nodo04','192.168.56.104','14'
UNION ALL SELECT 'V_productos_detalle','productos','VERTICAL',
'id,sku,descripcion,ficha_tecnica,imagen_url,peso','bdd-
nodo05','192.168.56.105','14'
) AS matriz
ORDER BY fase, tipo_frag, tabla_origen;
EOF
20

D.8 Crear el Documento de Diseño Distribuido en el host (host
— PowerShell)
PowerShell
$ddd = @"
# Documento de Diseño Distribuido — Laboratorio BDD
Generado en la Fase 9. Referencia técnica obligatoria para las Fases 10-16.
Fecha de generación: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
---
## 1. Esquema global
Base de datos : lab_bdd
Nodo de origen: bdd-nodo01 (192.168.56.101)
| Tabla | Filas | Motor | Atributo de distribución |
|------------------|-------|---------|-------------------------------------|
| clientes | 20 | InnoDB | region ENUM (fragmentación horiz.) |
| productos | 10 | InnoDB | columnas (fragmentación vertical) |
| pedidos | 20 | InnoDB | region ENUM (fragmentación horiz.) |
| detalle_pedidos | 36 | InnoDB | derivada de pedidos (co-localizada) |
---
## 2. Plan de replicación
### Fase 10 — Replicación física (maestro-esclavo)
| Nodo | IP | Rol | Modo de acceso |
|---------|----------------|---------|-----------------------|
| nodo01 | 192.168.56.101 | MAESTRO | Lectura + escritura |
| nodo02 | 192.168.56.102 | ESCLAVO | Solo lectura (RO) |
Método: binary log basado en GTID, replicación row-based.
### Fase 11 — Replicación lógica
| Nodo | IP | Rol |
|---------|----------------|----------------|
| nodo03 | 192.168.56.103 | MULTI-MAESTRO |
---
## 3. Plan de fragmentación horizontal (Fase 13)
Atributo de fragmentación: region
| Fragmento | Predicado | Nodo | IP
| Filas |
|-------------------|----------------------------------|--------|-------------
---|-------|
| clientes_frag_A | region IN ('norte','este') | nodo04 |
192.168.56.104 | 10 |
| clientes_frag_B | region IN ('sur','oeste') | nodo05 |
192.168.56.105 | 10 |
| pedidos_frag_A | region IN ('norte','este') | nodo04 |
192.168.56.104 | 10 |
| pedidos_frag_B | region IN ('sur','oeste') | nodo05 |
192.168.56.105 | 10 |
| detalle_frag_A | JOIN pedidos frag_A | nodo04 |
192.168.56.104 | ~18 |
21

| detalle_frag_B | JOIN pedidos frag_B | nodo05 |
192.168.56.105 | ~18 |
Correctitud verificada: completitud OK, disjunción OK, reconstrucción OK.
---
## 4. Plan de fragmentación vertical (Fase 14)
Tabla fuente: productos
| Fragmento | Columnas |
Nodo | IP |
|---------------------|-----------------------------------------------------|-
-------|----------------|
| V_productos_basico | id*, sku, nombre, categoria, precio, stock, fecha |
nodo04 | 192.168.56.104 |
| V_productos_detalle | id*, sku, descripcion, ficha_tecnica, imagen, peso |
nodo05 | 192.168.56.105 |
Clave de reconstrucción: JOIN en columna 'id'.
Correctitud verificada: completitud OK, disjunción de columnas OK,
reconstrucción OK.
---
## 5. Coordinador de consultas distribuidas (Fases 14-16)
Nodo : bdd-nodo06 (192.168.56.106)
Tecnología: Motor Spider de MariaDB
Rol : recibir consultas globales, descomponerlas en subconsultas
dirigidas a nodo04/nodo05 y combinar resultados.
---
## 6. Transparencia de distribución objetivo
| Tipo de transparencia | Mecanismo | Implementada
en |
|-----------------------|------------------------------------|----------------
-|
| Replicación | Maestro-esclavo transparente | Fases 10-
11 |
| Fragmentación | Spider oculta la partición | Fase
14+ |
| Ubicación | Spider oculta el nodo físico | Fase
14+ |
| Concurrencia | InnoDB MVCC + pruebas de fallo | Fase
17+ |
---
## 7. Historial de snapshots del laboratorio
| Snapshot | Estado en ese punto |
|------------------|-------------------------------------------------|
| fase05-completa | Ubuntu Server instalado, SSH activo |
| fase06-completa | IP estática configurada, SSH verificado |
| fase07-completa | MariaDB 10.11 instalado, utf8mb4 activo |
| fase08-completa | lab_bdd creada y poblada, usuarios, slow log |
| fase09-completa | Diseño distribuido definido y validado |
"@
$ruta = "C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md"
22

$ddd | Out-File -FilePath $ruta -Encoding UTF8
Write-Host "DDD creado en: $ruta"
# Verificar
Get-Item $ruta | Select-Object Name, Length, LastWriteTime
D.9 Apagar la VM y tomar los snapshots de cierre de fase (host)
Desde la sesión SSH abierta en bdd-nodo01 :
Bash
sudo poweroff
Confirmar desde el host que la VM se detuvo:
PowerShell
VBoxManage list runningvms
La salida debe estar vacía. Tomar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase09-completa" `
--description "Diseño distribuido validado: frag. horizontal
(clientes/pedidos/detalle), vertical (productos). DDD generado
en Documentacion/"
VBoxManage snapshot "bdd-nodo02" take "fase09-completa" `
--description "Sin cambios respecto a fase08-completa. Snapshot de hito de
diseño para coherencia de numeración."
Nota: bdd-nodo02 no recibió cambios en esta fase, pero se toma el snapshot
para mantener la coherencia de numeración entre ambos nodos, lo que simplifica
la identificación del estado de cada VM en cualquier punto del historial.
Confirmar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
23

Cada VM debe mostrar cinco snapshots:  fase05-completa  hasta  fase09-completa .
E. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen todos los puntos siguientes:
 El análisis estadístico (D) se ejecutó sin errores y el estudiante puede
interpretar los resultados  clientes por región distribución de tamaño
de columnas TEXT de  productos  (descripcion y ficha_tecnica ≈– bytes
promedio columnas operacionales ≈– bytes)
 Las tres condiciones de correctitud de la fragmentación horizontal de
| clientes  (D) devuelven  |     | OK  |     |     |
| -------------------------- | --- | ---- | --- | --- |
• Completitud suma de fragmentos = 
• Disjunción filas en intersección = 
• Reconstrucción UNION ALL produce  filas
 Las mismas tres condiciones se verificaron para  pedidos  (resultado  OK ) y
| la completitud para  |                 |  (resultado  |  con  filas en total) |     |
| -------------------- | --------------- | ------------ | ------------------------- | --- |
|                      | detalle_pedidos |              | OK                        |     |
 Las condiciones de correctitud de la fragmentación vertical de
productos
| (D) devuelven  | OK  |     |     |     |
| ---------------- | ---- | --- | --- | --- |
• Completitud los  productos aparecen en  V_basico  y en  V_detalle 
• Disjunción de columnas confirmada (sin columnas no clave compartidas)
• Reconstrucción JOIN por  id  produce  filas con todos los atributos
 Las cuatro consultas distribuidas simuladas (D) devuelven resultados no
vacíos y coherentes en particular la Consulta  devuelve exactamente  filas
(una por región) con datos de facturación correctos
 El diagrama de topología (D) se generó en   y
/tmp/topologia_lab_bdd.txt
el estudiante puede describir el rol de cada nodo sin leerlo
 La consulta de la matriz de asignación (D) muestra  filas una por cada
fragmento planificado ( replicadas +  horizontales +  verticales)
 El archivo  C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md  existe en
el host con un tamaño mayor a cero y contiene las siete secciones del diseño
 El estudiante puede explicar de memoria
| • Por qué  |                 |  se co-localiza con  |         |  (no se fragmenta |
| ---------- | --------------- | -------------------- | ------- | ----------------- |
|            | detalle_pedidos |                      | pedidos |                   |
independientemente)
| • Por qué la PK  | id         |  debe estar en ambos fragmentos verticales |            |     |
| ---------------- | ---------- | ------------------------------------------- | ---------- | --- |
| • Por qué        | bdd-nodo06 |  es el coordinador y no                     | bdd-nodo01 |    |
24

• La diferencia entre la fragmentación híbrida “en una sola tabla” y la que
emerge de combinar tablas con distintos tipos de fragmentación
 Los snapshots fase09-completa existen en bdd-nodo01 y bdd-nodo02 
25

F. Problemas comunes y soluciones
| Problema |     | Causa probable | Solución |     |     |
| -------- | --- | -------------- | -------- | --- | --- |
La verificación de  Los predicados IN no  Verificar con  SELECT DISTINCT
completitud devuelve  cubren todos los valores  region FROM clientes  que los
FALLA  para  del dominio de  region cuatro valores reales son
| clientes |     |     | exactamente                        | norte, sur, este,  |     |
| -------- | --- | --- | ---------------------------------- | ------------------ | --- |
|          |     |     | oeste  asegurarse de que los dos  |                    |     |
predicados formen una partición
completa del dominio
| La verificación de  |     | Los predicados de los  | Revisar que  |     |     |
| ------------------- | --- | ---------------------- | ------------ | --- | --- |
{'norte','este'} ∩
| disjunción devuelve un  |     | dos fragmentos  |     |     |  si se  |
| ----------------------- | --- | --------------- | --- | --- | -------- |
{'sur','oeste'} = ∅
| conteo >  |     | comparten algún valor  |     |     |     |
| ---------- | --- | ---------------------- | --- | --- | --- |
modificaron los predicados de
|     |     | de  region | ejemplo confirmar que no hay valor  |     |     |
| --- | --- | ---------- | ------------------------------------ | --- | --- |
compartido
La reconstrucción  El JOIN entre  Ejecutar  SELECT COUNT(*) FROM
vertical cuenta  fragmentos excluye filas  productos WHERE id IS NULL;  — en
menos filas que la  (posible valor NULL en  InnoDB la PK nunca es NULL si el
| tabla original |     | la PK) |     |     |     |
| -------------- | --- | ------ | --- | --- | --- |
resultado es >  hay corrupción de
datos que debe investigarse antes de
continuar
La consulta distribuida  La sesión no estaba en  Asegurar que el comando inicia con
simulada (D)  el contexto de  lab_bdd   sudo mariadb lab_bdd  (base de
devuelve  filas al ejecutar el bloque datos especificada) o agregar  USE
|     |     |     | lab_bdd; |  al inicio del bloque HERE- |     |
| --- | --- | --- | -------- | --------------------------- | --- |
DOC
Out-File  en  Comportamiento de  En PowerShell + usar  -Encoding
PowerShell x con
| PowerShell genera el  |     |     | - UTF8NoBOM |  en PowerShell x el  |     |
| --------------------- | --- | --- | ----------- | ------------------------ | --- |
archivo con
|     |     | Encoding UTF8 | BOM no afecta la legibilidad del  |     |     |
| --- | --- | ------------- | --------------------------------- | --- | --- |
codificación BOM o
archivo pero puede causar problemas
| con saltos de línea  |     |     | si se edita en ciertos programas |     |     |
| -------------------- | --- | --- | -------------------------------- | --- | --- |
incorrectos
El estudiante no puede  No se analizaron los  Revisar el Bloque  del análisis
justificar la elección de  datos antes de tomar la  estadístico (D): la distribución
region  como atributo  decisión uniforme de  clientes por región
| de fragmentación |     |     | confirma que  | region |  produce  |
| ---------------- | --- | --- | ------------- | ------ | --------- |
fragmentos balanceados un atributo
|     |     |     | desbalanceado (ej  |     | ciudad )  |
| --- | --- | --- | ------------------- | --- | --------- |
produciría hotspots
Hay dudas sobre si  Confusión entre  La disjunción aplica solo a columnas
| duplicar             |  en  | columnas clave y  | no clave                             |  es una clave  |     |
| -------------------- | ---- | ----------------- | ------------------------------------- | -------------- | --- |
|                      | sku  |                   |                                       | sku            |     |
| ambos fragmentos     |      | no clave          | alternativa (UNIQUE) y puede — y      |                |     |
| verticales viola la  |      |                   | conviene — aparecer en ambos          |                |     |
| disjunción           |      |                   | fragmentos para que las aplicaciones  |                |     |
puedan referenciar un producto sin
26

necesitar un JOIN cuando solo saben
el SKU Documentarlo como decisión
de diseño intencional
El snapshot de bdd- bdd-nodo02 quedó Ejecutar VBoxManage list
nodo02 falla porque la encendida desde una runningvms  si aparece apagarla
VM está activa sesión de trabajo con VBoxManage controlvm "bdd-
anterior nodo02" acpipowerbutton antes de
tomar el snapshot
La Consulta  (D) Algún cliente de alguna Verificar con SELECT DISTINCT
devuelve menos de región no tiene pedidos region FROM pedidos que los cuatro
 filas o las regiones están mal valores existen la Consulta  usa
escritas en /etc/hosts LEFT JOIN implícito vía JOIN por lo
(no aplica aquí) que regiones sin pedidos no
aparecerán — si se desea incluirlas
cambiar a LEFT JOIN
G. Checklist de validación
Ejecuté el análisis estadístico completo (D.2) en bdd-nodo01 y tomé nota de
los resultados: distribución por región, tamaño de columnas TEXT, FKs que
imponen co-localización.
Identifiqué region como atributo de fragmentación horizontal de clientes y
pedidos , con justificación cuantitativa (distribución uniforme, 5 filas por valor).
Definí los predicados de los dos fragmentos: frag_A = region IN ('norte','este') ,
frag_B = region IN ('sur','oeste') .
Las tres condiciones de correctitud de la fragmentación horizontal de clientes
devuelven OK : completitud, disjunción y reconstrucción.
Las mismas condiciones se verificaron para pedidos (OK) y la completitud para
detalle_pedidos (OK, 36 filas).
Definí los dos fragmentos verticales de productos : V_basico (columnas
operacionales de alta frecuencia) y V_detalle (columnas TEXT de baja frecuencia).
Las condiciones de correctitud de la fragmentación vertical devuelven OK :
completitud en ambos fragmentos, disjunción de columnas no clave, reconstrucción
por JOIN en id .
Ejecuté las cuatro consultas distribuidas simuladas (D.5) y confirmé resultados
correctos y no vacíos.
Generé el diagrama de topología (D.6) y puedo describir el rol de cada nodo.
Ejecuté la consulta de la matriz de asignación (D.7) y puedo explicar cada fila.
El archivo C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md existe y
contiene las siete secciones del diseño completo.
27

Apagué bdd-nodo01 de forma ordenada y tomé el snapshot fase09-completa
en bdd-nodo01 y bdd-nodo02 .
Puedo explicar la diferencia entre fragmentación horizontal, vertical e híbrida
usando ejemplos concretos del esquema lab_bdd .
Puedo justificar por qué detalle_pedidos se co-localiza con pedidos en lugar
de asignarse a un nodo independiente.
Puedo explicar por qué la PK id debe duplicarse en los dos fragmentos verticales
de productos .
Puedo describir el rol de bdd-nodo06 como coordinador y la tecnología que usará
(motor Spider de MariaDB).
Preguntas teóricas para estudiantes
 La fragmentación horizontal de clientes agrupa norte+este en un fragmento y
sur+oeste en otro en lugar de hacer un fragmento por cada valor de region
(cuatro fragmentos) Explica las ventajas e inconvenientes de ambas estrategias
¿Qué criterio debería dominar la decisión el número de nodos disponibles el
volumen de datos por fragmento la localidad de las consultas más frecuentes o la
facilidad de mantenimiento futuro del esquema de distribución?
 La tabla detalle_pedidos no tiene columna region propia pero el diseño la
co-localiza con los fragmentos de pedidos  Explica en detalle por qué esta
co-localización es correcta desde el punto de vista del rendimiento de las
consultas distribuidas ¿Qué problema concreto y medible (en términos de tráfico
de red y latencia) surgiría si detalle_pedidos se asignara a un único nodo
centralizado independientemente de la fragmentación de pedidos ?
 En la fragmentación vertical de productos  la columna sku aparece en
ambos fragmentos ( V_basico y V_detalle ) aunque la condición de disjunción
exige que las columnas no clave no se repitan ¿Está esto mal? Justifica
técnicamente por qué la duplicación de sku (siendo una clave alternativa
no la clave primaria) puede considerarse una decisión de diseño deliberada
y correcta y no una violación de la condición de disjunción
 El diseño establece que bdd-nodo06 actuará como coordinador usando el motor
Spider de MariaDB Describe conceptualmente cómo procesaría la Consulta
Distribuida  (de la sección D) en un sistema completamente distribuido
¿cuántas subconsultas generaría el coordinador a qué nodos se las enviaría
qué resultados intermedios recibiría y cómo los combinaría para producir
la respuesta final?
28

 El teorema CAP establece que ante una partición de red el sistema debe elegir
entre Consistencia y Disponibilidad Dado el diseño completo del laboratorio
(replicación en nodo– fragmentación en nodo– coordinador en nodo)
identifica al menos dos escenarios de fallo de red distintos y explica qué
dilema CAP presentaría cada uno ¿qué parte del sistema elegiría Consistencia
y qué parte elegiría Disponibilidad?
Ejercicios prácticos
 Script de validación automática de correctitud
Escribir un único script .sql que verifique las tres condiciones (completitud
disjunción reconstrucción) para las cuatro tablas incluidas en el plan de
fragmentación de forma automática El script debe producir una tabla con columnas
condicion  tabla y resultado ( OK / FALLA ) Ejecutarlo y documentar la
salida completa Modificar deliberadamente un predicado para introducir una violación
de disjunción o completitud observar cómo el script la detecta y restaurar el
predicado correcto
 Propuesta de fragmentación alternativa de cuatro fragmentos
Proponer un diseño de fragmentación horizontal para clientes que use cuatro
fragmentos (uno por valor de region ) pensado para un escenario futuro con
cuatro nodos de sharding (nodo a nodo) Reescribir los predicados identificar
el nodo destino de cada uno y ejecutar el equivalente del bloque D para
verificar la correctitud del diseño alternativo Discutir las ventajas y desventajas
frente al diseño de dos fragmentos actual
 Análisis del grado de localidad de cada consulta simulada
Para cada una de las cuatro consultas distribuidas de D indicar (a) qué
fragmentos necesita el coordinador (b) si la consulta se puede resolver accediendo
a un solo nodo o requiere múltiples nodos © cuál de las cuatro consultas tiene
el mayor grado de localidad (menor número de nodos involucrados) y cuál el menor
y (d) qué volumen estimado de datos intermedios (filas × bytes) debería transferirse
entre nodos para resolver cada consulta Apoyarse en las estadísticas del análisis D
Reto adicional para alumnos avanzados
Ampliar el plan de fragmentación para incluir a productos también en la
fragmentación horizontal, no solo en la vertical. Dado que productos no tiene
una columna region , proponer la adición de un atributo de partición (por ejemplo,
tipo_producto ENUM('hardware','mobiliario','accesorios') u otro atributo de negocio
29

que se pueda derivar del campo categoria existente), justificar la modificación del
DDL, redefinir la estrategia híbrida que combine la fragmentación vertical ya diseñada
con esta nueva fragmentación horizontal, y verificar las condiciones de correctitud
del esquema híbrido resultante. Incluir también el análisis de integridad referencial:
si detalle_pedidos tiene FK hacia productos , ¿cómo se gestionaría esa integridad
referencial en un sistema verdaderamente distribuido donde las FK no pueden cruzar
nodos? ¿Qué opciones ofrece MariaDB Spider para este escenario?
30

Criterios de evaluación para el profesor
Criterio Peso Indicador de logro
Análisis estadístico % Se ejecutaron los tres bloques de D y el
del esquema estudiante interpreta correctamente la
distribución de filas por región y el perfil de
tamaño de las columnas TEXT puede
relacionar cada métrica con una decisión
de diseño
Fragmentación horizontal % Los predicados de frag_A y frag_B
definición y correctitud están bien definidos para las tres tablas
involucradas las tres condiciones de
correctitud devuelven OK con la evidencia
SQL el estudiante puede explicar qué
significaría un resultado FALLA en cada
condición
Fragmentación vertical % Los dos fragmentos de productos están
definición y correctitud bien definidos con justificación de afinidad
de columnas las condiciones de
correctitud (incluida la reconstrucción por
JOIN) devuelven OK  el estudiante puede
explicar el rol de la PK duplicada
Consultas distribuidas % Las cuatro consultas de D producen
simuladas resultados correctos y no vacíos el
estudiante puede identificar qué
fragmentos consultaría el coordinador
para cada una y estimar el número de
nodos involucrados
Documento de Diseño % El archivo fase09-disenyo-
Distribuido distribuido.md existe es internamente
coherente y cubre las siete secciones
requeridas podrá usarse como referencia
sin ambigüedad en las Fases –
Comprensión conceptual % Las respuestas a las cinco preguntas usan
(preguntas teóricas) vocabulario técnico correcto (predicado
minterm completitud disjunción co-
localización coordinador CAP) y hacen
referencia explícita al esquema específico
del laboratorio
Preparación para la siguiente fase
La Fase 10: Replicación Física (Maestro-Esclavo) requerirá:
31

• El esquema lab_bdd idéntico y consistente en bdd-nodo01 y bdd-nodo02 (Fase )
• Snapshot fase09-completa tomado en ambas VMs (esta fase)
• Acceso SSH funcional desde el host hacia ambos nodos (Fase )
• El Documento de Diseño Distribuido disponible en
C:\LabBDD\Documentacion\fase09-disenyo-distribuido.md como referencia la
sección  define que nodo01 es el maestro y nodo02 el esclavo con binary log
basado en GTID y replicación row-based
• Ningún nodo adicional todavía bdd-nodo03  bdd-nodo04  bdd-nodo05 y
bdd-nodo06 no existen aún como VMs Se crearán en sus respectivas fases
En la Fase 10 se modificará la configuración de MariaDB en bdd-nodo01 (habilitando
el binary log, asignando un server-id único y configurando GTID) y en bdd-nodo02
(configurando el agente de replicación esclavo y el server-id propio), y se
verificará que los cambios escritos en el maestro se propagan automáticamente al
esclavo en tiempo real.
32

Fase 10 — Replicación Física (Maestro-Esclavo)
Continuación directa de la Fase 9. bdd-nodo01 y bdd-nodo02 tienen MariaDB
10.11 instalado con el esquema lab_bdd idéntico y poblado en ambos nodos, y el
snapshot fase09-completa está tomado. Esta fase convierte bdd-nodo01 en el
MAESTRO de replicación y bdd-nodo02 en su ESCLAVO: cualquier escritura
en el maestro se propagará automáticamente al esclavo en tiempo real usando binary
log en formato ROW con GTID de MariaDB. Al finalizar, el laboratorio tendrá su
primera capacidad de alta disponibilidad operativa: los datos del maestro quedan
preservados —y accesibles en modo lectura— en el esclavo de forma continua.
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Explicar el papel del binary log en la replicación física y las diferencias entre
los formatos STATEMENT ROW y MIXED justificando por qué se elige ROW
 Describir los dos hilos del esclavo (I/O thread y SQL thread) y la responsabilidad
individual de cada uno en el proceso de replicación
 Distinguir la replicación basada en posición de archivo (file+pos) de la basada en
GTID y articular por qué GTID simplifica la administración del esclavo
 Configurar el binary log con GTID en el nodo maestro mediante un archivo de
configuración dedicado sin alterar 50-server.cnf más allá del ajuste de
bind-address 
 Crear un usuario de replicación aplicando el principio de mínimo privilegio
( REPLICATION SLAVE ON *.* restringido a la IP exacta del esclavo)
 Establecer el enlace maestro-esclavo con CHANGE MASTER TO … MASTER_USE_GTID =
slave_pos y verificar que ambos hilos quedan en estado Yes 
 Verificar experimentalmente la propagación en tiempo real de INSERT UPDATE
DELETE y ALTER TABLE del maestro al esclavo
 Comprobar que read_only = ON bloquea escrituras directas de usuarios no
privilegiados en el esclavo
 Interpretar los campos clave de SHOW SLAVE STATUS y usar Seconds_Behind_Master
como indicador de lag de replicación
 Cerrar la fase con el snapshot fase10-completa en ambos nodos
1

B. Conceptos teóricos necesarios
1. El binary log y su rol en la replicación.
El binary log (binlog) es un archivo de registro secuencial que MariaDB escribe en el
maestro cada vez que se modifica el estado de los datos: DML ( INSERT ,  UPDATE ,
| ) y DDL ( |              | ,           | ,             | , etc.). Las consultas |     |
| --------- | ------------ | ----------- | ------------- | ---------------------- | --- |
| DELETE    | CREATE TABLE | ALTER TABLE | DROP DATABASE |                        |     |
de solo lectura ( SELECT ) no se registran. Los archivos se numeran progresivamente
| (                  | ,       | , …) y un archivo índice ( |     |                   | ) los |
| ------------------ | ------- | -------------------------- | --- | ----------------- | ----- |
| mariadb-bin.000001 | .000002 |                            |     | mariadb-bin.index |       |
rastrea. El parámetro  expire_logs_days  controla cuántos días se conservan antes de
purgarse.
El binlog tiene tres propósitos principales en un entorno de producción:
• Replicación el esclavo lee sus eventos para reproducirlos localmente
• Recuperación punto-en-tiempo (point-in-time recovery) restaurar una copia de
seguridad y aplicar los eventos del binlog hasta un instante preciso
• Auditoría de cambios reconstrucción forense de qué cambió y cuándo
2. Formatos del binary log.
2

| Formato   | Descripción    | Ventajas     | Inconvenientes   |
| --------- | -------------- | ------------ | ---------------- |
| STATEMENT | Registra la    | Compacto    | Inseguro con     |
|           | sentencia SQL  | legible con  | funciones no     |
|           | tal cual fue   | mysqlbinlog  |  deterministas  |
|           | ejecutada     |              | ( NOW()         |
UUID() 
RAND() ) el
esclavo puede
obtener valores
diferentes al
ejecutar la
misma
sentencia
| ROW | Registra los     | Completamente  | Mayor volumen   |
| --- | ---------------- | -------------- | --------------- |
|     | valores          | determinista  | en operaciones  |
|     | concretos        | correcto para  | masivas (ej    |
|     | (imagen antes y  | cualquier      | UPDATE … WHERE  |
|     | después) de      | sentencia     | 1  sin índice) |
cada fila
afectada
| MIXED | Usa              | Balance entre  | Menos            |
| ----- | ---------------- | -------------- | ---------------- |
|       | STATEMENT por    | los dos        | predecible en    |
|       | defecto cambia  | anteriores    | tamaño del log  |
|       | a ROW            |                | no               |
|       | automáticament   |                | recomendado      |
|       | e ante           |                | para GTID       |
sentencias no
deterministas
Este laboratorio usa  ROW  exclusivamente, que es el estándar recomendado para
producción, el único seguro con GTID y el requerido por las topologías multi-maestro
de la Fase 11.
3. Los dos hilos del esclavo.
La replicación funciona con dos hilos independientes que corren permanentemente en el
proceso MariaDB del esclavo:
• Hilo I/O (IO thread) actúa como cliente MariaDB Se conecta al maestro usando
el usuario de replicación solicita los eventos del binlog a partir de la última
posición GTID conocida los descarga y los almacena en el relay log local del
esclavo Su estado se reporta en  SHOW SLAVE STATUS  como  Slave_IO_Running 
• Hilo SQL (SQL thread) lee los eventos del relay log (ya locales sin depender
de la red) y los aplica al motor del esclavo exactamente en el orden en que fueron
generados en el maestro Su estado se reporta como  Slave_SQL_Running  La diferencia
3

entre el último evento descargado y el último aplicado determina el lag de replicación
( Seconds_Behind_Master )
Esta arquitectura de dos hilos desacopla la descarga de la aplicación: si el hilo SQL
falla por un error de datos, el hilo I/O puede seguir descargando eventos y el relay
log acumula las transacciones pendientes para cuando se corrija el error.
4. GTID en MariaDB.
GTID (Global Transaction Identifier) es un identificador único que MariaDB asigna a
cada transacción comprometida cuando el binary log está activo. En MariaDB (a diferencia
de MySQL), el formato es:
Text
domain_id - server_id - sequence_number
Por ejemplo,  1-1-42  representa la transacción número 42 generada por el servidor con
| server_id = 1 |  en el dominio de replicación  | 1 . Variables clave:                        |     |     |
| ------------- | ------------------------------ | ------------------------------------------- | --- | --- |
| Variable      | Nodo                           | Significado                                 |     |     |
|               | Ambos                          | Identificador único del nodo (obligatorio  |     |     |
server_id
dos nodos con el mismo valor
se rechazan)
| gtid_domain_i  | Ambos   | Dominio de replicación todos los nodos  |     |     |
| -------------- | ------- | ---------------------------------------- | --- | --- |
|                |         | del laboratorio usan                     |    |     |
| d              |         |                                          | 1   |     |
| gtid_binlog_po | Maestro | Último GTID escrito en el binlog         |     |     |
del maestro
s
| gtid_slave_po  | Esclavo | Último GTID aplicado por el esclavo  |                      |     |
| -------------- | ------- | ------------------------------------ | -------------------- | --- |
| s              |         | (persistido en                       | mysql.gtid_slave_pos | )  |
|                | Ambos   |  = el esclavo también escribe en su  |                      |     |
| log_slave_upda |         | ON                                   |                      |     |
propio binlog los eventos recibidos del
tes
maestro necesario para cadenas A→B→C
y para failover
Con  MASTER_USE_GTID = slave_pos , el esclavo comunica al maestro su  gtid_slave_pos
y el maestro le envía exactamente los eventos que el esclavo todavía no ha aplicado,
sin necesidad de conocer el nombre del archivo binlog ni la posición en bytes.
4

5. El relay log.
El relay log es el almacén local del esclavo para los eventos descargados del maestro.
Usa el mismo formato binario que el binlog. Una vez que el hilo SQL aplica un evento,
MariaDB puede purgarlo automáticamente ( relay_log_purge = ON ). El relay log también
se divide en archivos numerados y tiene su propio archivo índice.
6. read_only en el esclavo.
El parámetro read_only = ON impide que usuarios sin el privilegio SUPER ejecuten
DML o DDL directamente en el esclavo. Esto preserva la consistencia con el maestro: si
un usuario externo modifica datos directamente en el esclavo, crea una divergencia que
el binlog no conoce y que puede provocar errores en el hilo SQL cuando llegue la misma
transacción del maestro (ej. Duplicate entry o Row doesn't exist ). El hilo SQL del
esclavo opera como system user interno, que está exento de read_only .
7. Asincronismo y su implicación en la consistencia.
La replicación clásica maestro-esclavo es asíncrona: el maestro confirma la
transacción al cliente tan pronto como la escribe en su binlog local, sin esperar que
ningún esclavo la haya descargado ni aplicado. Ventaja: menor latencia para el cliente.
Riesgo: si el maestro cae justo después de confirmar y antes de que el esclavo descargue
el evento, ese evento se pierde en el esclavo (replication lag = data loss window).
La replicación semi-síncrona (plugin rpl_semi_sync ) mitiga esto obligando al maestro
a esperar el ACK de al menos un esclavo antes de confirmar; se introduce aquí como
concepto pero su implementación corresponde a fases avanzadas.
C. Procedimiento paso a paso
Paso 1 — Iniciar ambas VMs y conectarse por SSH.
Paso 2 — Modificar bind-address en el maestro (nodo01).
El esclavo conecta al puerto 3306 del maestro a través de la red Host-Only. La
configuración actual bind-address = 127.0.0.1 impide conexiones desde otras IPs.
Se cambia a 0.0.0.0 (todas las interfaces), lo cual es seguro en la red Host-Only
aislada de este laboratorio.
Paso 3 — Crear el archivo de configuración de replicación del maestro.
Se crea /etc/mysql/mariadb.conf.d/60-replication-master.cnf con los parámetros de
binary log, GTID y server_id . Al usar prefijo 60 , queda cargado después de
50-server.cnf (cuya configuración base se conserva intacta) y antes de
99-lab-logs.cnf .
Paso 4 — Reiniciar MariaDB en el maestro y verificar que el binlog quedó activo.
5

Paso 5 — Crear el usuario de replicación en el maestro.
Se crea repl_user@'192.168.56.102' con el privilegio mínimo REPLICATION SLAVE .
Restringir el host a la IP exacta del esclavo es esencial: un usuario repl_user@'%'
permitiría que cualquier máquina de la red se hiciera pasar por el esclavo.
Paso 6 — Registrar la posición GTID del maestro como referencia de partida.
Confirmar que gtid_binlog_pos inicial es vacío: ninguna transacción con GTID se ha
aplicado desde que se habilitó el binlog. Este es el punto de sincronía: ambos nodos
tienen los mismos datos históricos (cargados en la Fase 8) y el esclavo comenzará a
recibir solo los cambios futuros del maestro.
Paso 7 — Crear el archivo de configuración de replicación del esclavo (nodo02).
Se crea /etc/mysql/mariadb.conf.d/60-replication-slave.cnf con server_id = 2 ,
configuración del relay log y read_only = ON .
Paso 8 — Reiniciar MariaDB en el esclavo y verificar sus variables.
Paso 9 — Configurar el enlace de replicación en el esclavo con CHANGE MASTER TO .
Paso 10 — Iniciar los hilos de replicación con START SLAVE .
Paso 11 — Verificar el estado de replicación con SHOW SLAVE STATUS .
Confirmar que Slave_IO_Running y Slave_SQL_Running son Yes y
Seconds_Behind_Master es 0 .
Paso 12 — Pruebas de propagación: INSERT, UPDATE, DELETE y ALTER TABLE en el maestro.
Ejecutar cada operación en nodo01 y confirmar en nodo02 que el cambio aparece en
tiempo real.
Paso 13 — Prueba de read_only : intentar escribir directamente en el esclavo.
Confirmar que el esclavo rechaza escrituras de usuarios sin privilegio SUPER .
Paso 14 — Monitoreo de lag y posición GTID en ambos nodos.
Paso 15 — Apagar ambas VMs y tomar el snapshot fase10-completa .
D. Comandos completos
Los bloques (host) se ejecutan en PowerShell en Windows. Los bloques
(VM — nodoXX) se ejecutan en una sesión SSH al nodo indicado. Los bloques SQL
dentro de sudo mariadb se ejecutan directamente en el prompt del motor.
6

D.1 Iniciar ambas VMs y conectarse por SSH (host)
PowerShell
VBoxManage startvm "bdd-nodo01" --type headless
VBoxManage startvm "bdd-nodo02" --type headless
Esperar 30 segundos y abrir dos terminales SSH simultáneas:
PowerShell
# Terminal 1 — maestro
ssh bddadmin@192.168.56.101
# Terminal 2 — esclavo (segunda ventana de PowerShell)
ssh bddadmin@192.168.56.102
D.2 Modificar bind-address en el maestro (VM — nodo01)
El archivo 50-server.cnf tiene bind-address = 127.0.0.1 . Se cambia a 0.0.0.0
para que el esclavo pueda conectarse al puerto 3306 a través de la red Host-Only:
Bash
# Ver el valor actual antes de modificar
grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf
# Reemplazar la línea (el patrón cubre posibles espacios alrededor del =)
sudo sed -i \
's/^bind-address[](:space:)*=.*/bind-address =
0.0.0.0/' \
/etc/mysql/mariadb.conf.d/50-server.cnf
# Confirmar el cambio
grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf
Salida esperada después del cambio:
Text
bind-address = 0.0.0.0
7

Si la línea bind-address no existe en 50-server.cnf o está comentada, agregarla
explícitamente con echo 'bind-address = 0.0.0.0' | sudo tee -a
/etc/mysql/mariadb.conf.d/50-server.cnf y verificar con grep bind-address
/etc/mysql/*.cnf /etc/mysql/**/*.cnf que no hay otro archivo que la defina.
8

D.3 Crear el archivo de configuración de replicación del maestro (VM
— nodo01)
Bash
sudo tee /etc/mysql/mariadb.conf.d/60-replication-master.cnf > /dev/null
<< 'EOF'
# ===========================================================
# Configuración de replicación — ROL: MAESTRO
# Nodo: bdd-nodo01 | IP: 192.168.56.101 | server_id: 1
# Fase 10 del Laboratorio BDD.
# Cargado después de 50-server.cnf (número de archivo mayor).
# ===========================================================
[mariadb]
# --- Identificación única del nodo (NUNCA debe repetirse en el
ecosistema) ---
server_id = 1
# --- Binary log ---
# Prefijo de los archivos de binlog en /var/log/mysql/
log_bin = /var/log/mysql/mariadb-bin
# ROW: registra valores concretos de cada fila, no la sentencia SQL.
# Obligatorio para GTID y para replicación multi-maestro (Fase 11).
binlog_format = ROW
# Retención automática de archivos binlog (en días)
expire_logs_days = 7
# Tamaño máximo por archivo antes de rotar al siguiente
max_binlog_size = 100M
# Incluir la sentencia SQL original en eventos ROW (facilita mysqlbinlog)
binlog_annotate_row_events = ON
# Garantiza que el binlog se escribe a disco en cada COMMIT
# (consistencia máxima; puede reducir rendimiento en disco lento)
sync_binlog = 1
# --- GTID ---
# Dominio de replicación del laboratorio (todos los nodos usan 1)
gtid_domain_id = 1
# El maestro también escribe en su binlog los eventos que recibe de otros
# (necesario para cadenas A→B→C y para failover controlado)
log_slave_updates = ON
# --- Seguridad de red ---
# Evitar resolución DNS por hostname: más rápido y previene errores
# cuando el DNS no responde. Los GRANTs deben usar IPs, no nombres.
skip_name_resolve = ON
EOF
Verificar que el archivo se creó correctamente:
9

Bash
cat /etc/mysql/mariadb.conf.d/60-replication-master.cnf
D.4 Reiniciar MariaDB en el maestro y verificar el binary log activo (VM
— nodo01)
Bash
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager -l
La salida debe mostrar active (running) . Si el servicio no arranca, revisar el log:
Bash
sudo journalctl -u mariadb --no-pager -n 40
Verificar que el binary log y las variables de replicación quedaron activos:
Bash
sudo mariadb << 'EOF'
-- ¿Está el binlog habilitado?
SHOW VARIABLES LIKE 'log_bin';
-- ¿Cuál es el formato?
SHOW VARIABLES LIKE 'binlog_format';
-- server_id, GTID y otras variables de replicación
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'gtid_domain_id';
SHOW VARIABLES LIKE 'log_slave_updates';
SHOW VARIABLES LIKE 'sync_binlog';
-- ¿El motor ahora escucha en 0.0.0.0?
SHOW VARIABLES LIKE 'bind_address';
-- Listar archivos binlog existentes (debe haber mariadb-bin.000001)
SHOW BINARY LOGS;
-- Estado completo del maestro: archivo actual, posición y GTID
SHOW MASTER STATUS;
EOF
10

Salida esperada de SHOW MASTER STATUS (los valores numéricos variarán):
Text
+--------------------+----------+--------------+------------------+-------
----------+
| File | Position | Binlog_Do_DB | Binlog_Ignore_DB |
Gtid_binlog_pos |
+--------------------+----------+--------------+------------------+-------
----------+
| mariadb-bin.000001 | 351 | |
| |
+--------------------+----------+--------------+------------------+-------
----------+
El campo Gtid_binlog_pos estará vacío o mostrará 0-1-N si el motor ya escribió
algún evento interno. Anotar el valor exacto: es el punto de partida del esclavo.
D.5 Crear el usuario de replicación en el maestro (VM — nodo01)
Bash
sudo mariadb << 'EOF'
-- ----------------------------------------------------------------
-- Usuario de replicación
-- El host '192.168.56.102' restringe el acceso a la IP exacta
-- del esclavo (principio de mínimo privilegio).
-- Se usa mysql_native_password porque el protocolo de replicación
-- binaria no soporta auth_socket.
-- ----------------------------------------------------------------
CREATE USER IF NOT EXISTS 'repl_user'@'192.168.56.102'
IDENTIFIED BY 'ReplUser_2025!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'192.168.56.102';
FLUSH PRIVILEGES;
-- Verificar que el usuario fue creado con el host correcto
SELECT User, Host, plugin
FROM mysql.user
WHERE User = 'repl_user';
-- Verificar que tiene exactamente REPLICATION SLAVE y nada más
SHOW GRANTS FOR 'repl_user'@'192.168.56.102';
EOF
11

Salida esperada de SHOW GRANTS :
Text
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'192.168.56.102' IDENTIFIED
BY PASSWORD '...'
D.6 Registrar la posición GTID de partida (VM — nodo01)
Bash
sudo mariadb -e "SELECT @@global.gtid_binlog_pos AS gtid_inicio_maestro;"
sudo mariadb -e "SHOW MASTER STATUS\G"
Punto de sincronía importante: en este momento bdd-nodo01 tiene el binlog
habilitado pero no ha recibido ninguna transacción de aplicación desde la habilitación.
Ambos nodos tienen la misma base de datos lab_bdd con los datos de la Fase 8.
El esclavo comenzará a replicar exactamente desde este punto en adelante.
Entre este paso y START SLAVE del Paso 10, no ejecutar ninguna operación DML
ni DDL en bdd-nodo01 . Si lo haces, esas transacciones quedarán en el binlog y
el esclavo intentará aplicarlas sobre datos que ya tiene, generando un error
Duplicate entry en el hilo SQL.
12

D.7 Crear el archivo de configuración de replicación del esclavo (VM
— nodo02)
Bash
sudo tee /etc/mysql/mariadb.conf.d/60-replication-slave.cnf > /dev/null
<< 'EOF'
# ===========================================================
# Configuración de replicación — ROL: ESCLAVO
# Nodo: bdd-nodo02 | IP: 192.168.56.102 | server_id: 2
# Fase 10 del Laboratorio BDD.
# ===========================================================
[mariadb]
# --- Identificación única del nodo ---
server_id = 2
# --- Relay log: almacena eventos descargados del maestro ---
relay_log = /var/log/mysql/mariadb-relay-bin
relay_log_index = /var/log/mysql/mariadb-relay-bin.index
# Purgar automáticamente los segmentos del relay log ya aplicados
relay_log_purge = ON
# --- Binary log del esclavo ---
# Necesario para log_slave_updates y para que este nodo pueda
# convertirse en maestro de otro esclavo en el futuro (failover)
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
# Escribir en el binlog propio los eventos recibidos del maestro
log_slave_updates = ON
# --- GTID (debe coincidir con el maestro) ---
gtid_domain_id = 1
# --- Protección de escrituras directas ---
# Rechaza DML/DDL de usuarios sin privilegio SUPER
# El hilo SQL de replicación (system user) está exento
read_only = ON
# --- Seguridad de red ---
skip_name_resolve = ON
EOF
Verificar el archivo:
Bash
cat /etc/mysql/mariadb.conf.d/60-replication-slave.cnf
13

D.8 Reiniciar MariaDB en el esclavo y verificar sus variables (VM
— nodo02)
Bash
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager -l
Verificar las variables clave del esclavo:
Bash
sudo mariadb << 'EOF'
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'read_only';
SHOW VARIABLES LIKE 'relay_log';
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'gtid_domain_id';
SHOW VARIABLES LIKE 'log_slave_updates';
-- Confirmar que aún no hay enlace configurado (resultado vacío)
SHOW SLAVE STATUS\G
EOF
SHOW SLAVE STATUS debe devolver un resultado vacío porque aún no se ejecutó
CHANGE MASTER TO .
14

D.9 Configurar el enlace de replicación en el esclavo (VM — nodo02)
Bash
sudo mariadb << 'EOF'
-- ----------------------------------------------------------------
-- CHANGE MASTER TO: define de dónde y cómo replicar.
--
-- MASTER_USE_GTID = slave_pos:
-- El esclavo enviará su gtid_slave_pos al maestro.
-- Como está vacío (ningún GTID aplicado aún), el maestro enviará
-- desde el inicio del binary log — exactamente lo que queremos,
-- porque los datos actuales en ambos nodos provienen de la Fase 8
-- (antes de que el binlog existiera) y solo se replicarán cambios
-- futuros.
-- ----------------------------------------------------------------
CHANGE MASTER TO
MASTER_HOST = '192.168.56.101',
MASTER_PORT = 3306,
MASTER_USER = 'repl_user',
MASTER_PASSWORD = 'ReplUser_2025!',
MASTER_USE_GTID = slave_pos;
-- Verificar que la configuración se almacenó (sin iniciar todavía)
SHOW SLAVE STATUS\G
EOF
En la salida de SHOW SLAVE STATUS , antes de iniciar, confirmar:
• Master_Host: 192.168.56.101
• Master_User: repl_user
• Master_Port: 3306
• Using_Gtid: Slave_Possudo
• Slave_IO_Running: No (todavía no iniciado)
• Slave_SQL_Running: No (todavía no iniciado)
15

D.10 Iniciar los hilos de replicación (VM — nodo02)
Bash
sudo mariadb -e "START SLAVE;"
# Dar 5 segundos para que los hilos establezcan la conexión inicial
sleep 5
sudo mariadb -e "SHOW SLAVE STATUS\G"
Campos críticos a verificar:
Text
Slave_IO_Running: Yes ← hilo I/O conectado al maestro ✓
Slave_SQL_Running: Yes ← hilo SQL aplicando eventos ✓
Seconds_Behind_Master: 0 ← sin retraso ✓
Master_Host: 192.168.56.101
Master_User: repl_user
Using_Gtid: Slave_Pos
Gtid_IO_Pos: ← GTID hasta el que se descargó
Last_IO_Error: ← vacío = sin errores ✓
Last_SQL_Error: ← vacío = sin errores ✓
Si cualquiera de los dos hilos muestra No , revisar Last_IO_Error y
Last_SQL_Error y consultar la sección F.
D.11 Pruebas de propagación en tiempo real (VM — nodo01 y nodo02)
Ejecutar cada bloque de nodo01 y verificar inmediatamente en nodo02.
Prueba 1 — INSERT
En bdd-nodo01 (maestro):
16

Bash
sudo mariadb lab_bdd << 'EOF'
INSERT INTO clientes (nombre, apellido, email, telefono, region, ciudad)
VALUES ('Test', 'Replicacion', 'test.repl@lab.test', '5550000001',
'norte', 'CDMX');
-- Confirmar que la fila existe en el maestro
SELECT id, nombre, apellido, region, ciudad
FROM clientes
WHERE email = 'test.repl@lab.test';
EOF
En bdd-nodo02 (esclavo), verificar que la fila apareció sin haberla insertado ahí:
Bash
sudo mariadb lab_bdd -e "
SELECT id, nombre, apellido, region, ciudad
FROM clientes
WHERE email = 'test.repl@lab.test';
"
Prueba 2 — UPDATE
En bdd-nodo01 :
Bash
sudo mariadb lab_bdd -e "
UPDATE clientes
SET ciudad = 'Guadalajara', region = 'oeste'
WHERE email = 'test.repl@lab.test';
"
En bdd-nodo02 , verificar el cambio:
17

Bash
sudo mariadb lab_bdd -e "
SELECT id, nombre, ciudad, region
FROM clientes
WHERE email = 'test.repl@lab.test';
"
La ciudad debe ser Guadalajara y la región oeste .
Prueba 3 — DELETE
En bdd-nodo01 :
Bash
sudo mariadb lab_bdd -e "
DELETE FROM clientes WHERE email = 'test.repl@lab.test';
"
En bdd-nodo02 , verificar que la fila desapareció:
Bash
sudo mariadb lab_bdd -e "
SELECT COUNT(*) AS debe_ser_cero
FROM clientes
WHERE email = 'test.repl@lab.test';
"
Prueba 4 — DDL (ALTER TABLE)
En bdd-nodo01 , agregar una columna de auditoría:
18

Bash
sudo mariadb lab_bdd -e "
ALTER TABLE clientes
ADD COLUMN ultima_modificacion DATETIME
DEFAULT CURRENT_TIMESTAMP
ON UPDATE CURRENT_TIMESTAMP
AFTER fecha_alta;
"
En bdd-nodo02 , verificar que la columna se replicó:
Bash
sudo mariadb lab_bdd -e "SHOW COLUMNS FROM clientes
LIKE 'ultima_modificacion';"
Prueba 5 — Verificación de conteo global de datos
Ejecutar en ambos nodos y comparar los resultados; deben ser idénticos:
Bash
sudo mariadb -e "
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM lab_bdd.clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM
lab_bdd.productos UNION ALL
SELECT 'pedidos', COUNT(*) FROM lab_bdd.pedidos
UNION ALL
SELECT 'detalle_pedidos', COUNT(*)
FROM lab_bdd.detalle_pedidos;
"
Salida esperada (idéntica en nodo01 y nodo02):
19

Text
+-----------------+-------+
| tabla | filas |
+-----------------+-------+
| clientes | 20 |
| productos | 10 |
| pedidos | 20 |
| detalle_pedidos | 36 |
+-----------------+-------+
D.12 Prueba de read_only en el esclavo (VM — nodo02)
Bash
# Intento con app_user (no tiene SUPER)
mariadb -u app_user -p'AppUser_2025!' lab_bdd \
-e "INSERT INTO clientes (nombre, apellido, email, region)
VALUES ('Intento', 'Directo', 'intento@lab.test', 'norte');" \
2>&1
# Intento con lab_admin (tampoco tiene SUPER)
mariadb -u lab_admin -p'LabAdmin_2025!' lab_bdd \
-e "INSERT INTO clientes (nombre, apellido, email, region)
VALUES ('Intento', 'Admin', 'intento.admin@lab.test', 'norte');" \
2>&1
Ambos intentos deben producir el error:
Text
ERROR 1290 (HY000): The MariaDB server is running with the --read-
only option
so it cannot execute this statement
20

D.13 Monitoreo de lag y posición GTID (VM — ambos nodos)
Bash
# En nodo01: posición GTID actual del binlog del maestro
sudo mariadb -e "SELECT @@global.gtid_binlog_pos
AS posicion_gtid_maestro;"
sudo mariadb -e "SHOW MASTER STATUS\G"
# En nodo02: posición GTID aplicada por el esclavo y estado de hilos
sudo mariadb -e "SELECT @@global.gtid_slave_pos AS posicion_gtid_esclavo;"
sudo mariadb -e "SHOW SLAVE STATUS\G" | \
grep -E
'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind|Gtid|Last.*Error'
Para monitoreo continuo del lag (se actualiza cada 2 segundos; Ctrl+C para salir):
Bash
watch -n 2 "sudo mariadb -e 'SHOW SLAVE STATUS\G' 2>/dev/null | \
grep -E
'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Gtid_IO_Pos'"
El gtid_slave_pos del esclavo debe coincidir con el gtid_binlog_pos del maestro
cuando Seconds_Behind_Master es 0 , indicando que no hay retraso.
D.14 Apagar ambas VMs y tomar el snapshot fase10-completa (host)
Desde las sesiones SSH de cada nodo:
Bash
# En la terminal SSH de nodo01
sudo poweroff
# En la terminal SSH de nodo02
sudo poweroff
Confirmar desde el host que ambas VMs están detenidas:
21

PowerShell
VBoxManage list runningvms
La salida debe estar vacía. Tomar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase10-completa" `
--description "MAESTRO: binlog ROW + GTID habilitado. server_id=1. repl_user
creado para 192.168.56.102. bind-address=0.0.0.0. Pruebas
INSERT/UPDATE/DELETE/DDL verificadas."
VBoxManage snapshot "bdd-nodo02" take "fase10-completa" `
--description "ESCLAVO: read_only=ON. server_id=2. CHANGE MASTER TO con
MASTER_USE_GTID=slave_pos hacia 192.168.56.101. Slave_IO=Yes, Slave_SQL=Yes.
Columna ultima_modificacion replicada vía DDL."
Confirmar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
Cada VM debe mostrar seis snapshots: fase05-completa hasta fase10-completa .
E. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen todos los puntos siguientes en
el estado de los nodos encendidos:
 SHOW VARIABLES LIKE 'log_bin' devuelve ON en bdd-nodo01 
 SHOW BINARY LOGS muestra al menos mariadb-bin.000001 en bdd-nodo01 
 SHOW VARIABLES LIKE 'binlog_format' devuelve ROW en bdd-nodo01 
 SHOW VARIABLES LIKE 'server_id' devuelve 1 en bdd-nodo01 y 2 en
bdd-nodo02 
 SHOW GRANTS FOR 'repl_user'@'192.168.56.102' en bdd-nodo01 muestra
exactamente GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'192.168.56.102' 
 SHOW SLAVE STATUS\G en bdd-nodo02 muestra
• Slave_IO_Running: Yes
22

• Slave_SQL_Running: Yes
• Seconds_Behind_Master: 0
• Last_IO_Error: (vacío)
• Last_SQL_Error: (vacío)
• Using_Gtid: Slave_Pos
 SHOW VARIABLES LIKE 'read_only' devuelve ON en bdd-nodo02 
 La columna ultima_modificacion (añadida en la Prueba  de DDL) existe en la tabla
clientes de ambos nodos
 Los conteos de las cuatro tablas de lab_bdd son idénticos en ambos nodos
( /  /  /  registros)
 Los intentos de INSERT directo con app_user y lab_admin en bdd-nodo02 fallan
con ERROR 1290: read-only 
 El gtid_slave_pos del esclavo coincide con el gtid_binlog_pos del maestro
 Los snapshots fase10-completa existen en bdd-nodo01 y bdd-nodo02 
 El estudiante puede explicar sin ver el documento la diferencia entre el hilo I/O
y el hilo SQL y qué ocurre si solo uno de los dos falla
23

F. Problemas comunes y soluciones
| Problema |     | Causa probable | Solución |     |     |
| -------- | --- | -------------- | -------- | --- | --- |
Slave_IO_Running: No   bind-address  sigue  En nodo:  grep bind-address
Last_IO_Error: "Can't  siendo  127.0.0.1  en  /etc/mysql/mariadb.conf.d/5
connect to MySQL server  nodo el  sed  no se  0-server.cnf  si aún muestra
on '192.168.56.101'" aplicó o el servicio no se  127.0.0.1  ejecutar el  sed  de
|     |     | reinició | nuevo y  sudo systemctl  |     |     |
| --- | --- | -------- | ------------------------ | --- | --- |
restart mariadb
Slave_IO_Running: No   El usuario fue creado con  En nodo:  SELECT User, Host
Last_IO_Error: "Access  host incorrecto o la  FROM mysql.user WHERE
denied for user  contraseña difiere User='repl_user';  si el host
| 'repl_user'@'192.168.56.1 |     |     | es incorrecto              | DROP USER  |     |
| ------------------------- | --- | --- | --------------------------- | ---------- | --- |
| 02'"                      |     |     | 'repl_user'@'host_incorrect |            |     |
o';  y recrear con la IP exacta
Slave_SQL_Running: No   Se ejecutó DML en  Para omitir ese evento puntual
Last_SQL_Error:  nodo después de  (solo si no representa pérdida
"Duplicate entry 'X' for  habilitar el binlog y antes  de datos crítica)  STOP SLAVE;
de que el esclavo iniciara
| key 'PRIMARY'" |     |     | SET GLOBAL  |     |     |
| -------------- | --- | --- | ----------- | --- | --- |
el esclavo intenta insertar
SQL_SLAVE_SKIP_COUNTER = 1;
datos que ya existen
|     |     |     | START SLAVE; |  Si el problema  |     |
| --- | --- | --- | ------------ | ---------------- | --- |
se repite ver el reto avanzado
para resincronización completa
Slave_IO_Running: No   Puerto  bloqueado  En nodo:  sudo ufw status 
Last_IO_Error: "error  por firewall (ufw  si está activo  sudo ufw allow
connecting … errno: 111  o iptables activo  from 192.168.56.102 to any
| Connection refused" |     | en nodo) | port 3306 proto tcp |     |     |
| ------------------- | --- | ---------- | ------------------- | --- | --- |
MariaDB no arranca en  Error de sintaxis en el  sudo journalctl -u mariadb
nodo después de crear  archivo de configuración --no-pager -n 30  buscar
| 60-replication- |     |     | línea  [ERROR] |  o  unknown    |     |
| --------------- | --- | --- | -------------- | -------------- | --- |
| master.cnf      |     |     | variable       |  corregir el  |     |
parámetro indicado
|     |     | El  |  se  |     |     |
| --- | --- | --- | ---- | --- | --- |
SHOW SLAVE STATUS CHANGE MASTER TO STOP SLAVE; CHANGE MASTER
muestra  Using_Gtid: No  en  ejecutó sin  TO MASTER_USE_GTID =
lugar de  Slave_Pos MASTER_USE_GTID =  slave_pos; START SLAVE;
slave_pos
El  sed  no encontró la línea  El parámetro está  grep -r bind-address
bind-address  en  50- comentado o en  /etc/mysql/  para localizarlo
| server.cnf |     | otro archivo | descomentarlo o agregar  |     | bind- |
| ---------- | --- | ------------ | ------------------------ | --- | ----- |
|            |     |              | address = 0.0.0.0        |     |       |
explícitamente en
60-
replication-master.cnf
24

Seconds_Behind_Master   El hilo SQL no puede  Verificar con  SHOW
crece indefinidamente sin  aplicar eventos tan rápido  PROCESSLIST  en nodo qué
como el I/O los descarga
| llegar a  |     |     | está haciendo el hilo SQL  |             |     |
| ---------- | --- | --- | -------------------------- | ----------- | --- |
|            |     |     | ( System lock              |   Updating |    |
etc) comprobar que el disco
de nodo no está saturado
con
iostat -x 1
SHOW GRANTS FOR  Los eventos  CREATE  Comportamiento correcto El
'repl_user'@'192.168.56.1 USER  y  GRANT  del  usuario  repl_user  en nodo
02'  también aparece en  maestro se replicaron al  es inofensivo no tiene
| nodo | esclavo como es  |     | privilegios dañinos y no puede  |     |     |
| ------ | ----------------- | --- | ------------------------------- | --- | --- |
|        | esperado          |     | ser usado para configurar una   |     |     |
replicación entrante al esclavo
read_only  no bloquea  root  tiene el privilegio  Comportamiento correcto
escrituras del usuario  root SUPER  que está exento  read_only  protege de
|     | de  read_only |  por diseño | escrituras accidentales de  |     |     |
| --- | ------------- | ----------- | --------------------------- | --- | --- |
aplicaciones no de
administradores Para bloquear
|     |     |     | también a                   | SUPER  usar  | SET  |
| --- | --- | --- | --------------------------- | ------------- | ---- |
|     |     |     | GLOBAL super_read_only = ON |               |      |
(con precaución bloquea al hilo
SQL si se activa antes de que
esté conectado)
El  ALTER TABLE  de la  La columna  En nodo:  STOP SLAVE; SET
| Prueba  falla en nodo  | ultima_modificacion |     | GLOBAL  |     |     |
| ------------------------- | ------------------- | --- | ------- | --- | --- |
con “Column already exists” se añadió directamente  SQL_SLAVE_SKIP_COUNTER = 1;
|     | en nodo antes de esta  |     |     |  En el futuro  |     |
| --- | ------------------------ | --- | --- | ---------------- | --- |
START SLAVE;
|     | prueba |     | nunca ejecutar DDL  |     |     |
| --- | ------ | --- | ------------------- | --- | --- |
directamente en el esclavo
MariaDB en nodo arranca  START SLAVE  no persiste  Verificar  SHOW SLAVE STATUS\G
pero la replicación no se  entre reinicios si hay un  después del reinicio ejecutar
inicia automáticamente tras
|     | error de hilo al arrancar |     | START SLAVE |  manualmente si  |     |
| --- | ------------------------- | --- | ----------- | ---------------- | --- |
un reinicio
|     |     |     | los hilos están en    | No      |  Para  |
| --- | --- | --- | --------------------- | ------- | ------- |
|     |     |     | arranque automático  |         | --skip- |
|     |     |     | slave-start=0         |  en la  |         |
configuración (por defecto los
hilos arrancan automáticamente
en MariaDB )
G. Checklist de validación
grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf  devuelve  0.0.0.0
en  bdd-nodo01 .
25

El archivo  60-replication-master.cnf  existe en  bdd-nodo01  con  server_id = 1 ,
| log_bin                       | ,  binlog_format = ROW |     |     |     |  y         | gtid_domain_id = 1 |     |                 | .   |     |     |     |     |
| ----------------------------- | ---------------------- | --- | --- | --- | ---------- | ------------------ | --- | --------------- | --- | --- | --- | --- | --- |
| SHOW VARIABLES LIKE 'log_bin' |                        |     |     |     |  devuelve  |                    | ON  |  en  bdd-nodo01 |     |     | .   |     |     |
SHOW BINARY LOGS  muestra al menos el archivo  mariadb-bin.000001  en  bdd-nodo01 .
SHOW GRANTS FOR 'repl_user'@'192.168.56.102'  muestra  GRANT REPLICATION SLAVE
|             |                          |  en            |     |  y el usuario no existe con host distinto de  |     |             |     |            |     |       |                |     | .   |
| ----------- | ------------------------ | -------------- | --- | --------------------------------------------- | --- | ----------- | --- | ---------- | --- | ----- | -------------- | --- | --- |
|     ON *.*  |                          | bdd-nodo01     |     |                                               |     |             |     |            |     |       | 192.168.56.102 |     |     |
| El archivo  |                          |                |     |                                               |     |  existe en  |     |            |     |  con  |                | ,   |     |
|             | 60-replication-slave.cnf |                |     |                                               |     |             |     | bdd-nodo02 |     |       | server_id = 2  |     |     |
| relay_log   |  y                       | read_only = ON |     |                                               | .   |             |     |            |     |       |                |     |     |
SHOW VARIABLES LIKE 'server_id'  devuelve  1  en nodo01 y  2  en nodo02.
SHOW VARIABLES LIKE 'read_only'  devuelve  ON  en  bdd-nodo02 .
SHOW SLAVE STATUS\G  en  bdd-nodo02  muestra  Slave_IO_Running: Yes .
SHOW SLAVE STATUS\G  en  bdd-nodo02  muestra  Slave_SQL_Running: Yes .
| Seconds_Behind_Master |     |     |                |  es  | 0  en  | bdd-nodo02        |     | .   |            |     |     |     |     |
| --------------------- | --- | --- | -------------- | ---- | ------ | ----------------- | --- | --- | ---------- | --- | --- | --- | --- |
| Last_IO_Error         |     |  y  | Last_SQL_Error |      |        |  están vacíos en  |     |     | bdd-nodo02 |     | .   |     |     |
Using_Gtid: Slave_Pos  aparece en  SHOW SLAVE STATUS  de  bdd-nodo02 .
| El INSERT de prueba ( |     |     |                    |     |     |     | ) apareció en  |     |            |     |  sin ejecutarlo |     |     |
| --------------------- | --- | --- | ------------------ | --- | --- | --- | -------------- | --- | ---------- | --- | --------------- | --- | --- |
|                       |     |     | test.repl@lab.test |     |     |     |                |     | bdd-nodo02 |     |                 |     |     |
ahí directamente.
| El UPDATE (ciudad →           |     |     | Guadalajara |            |     | ) se reflejó en  |     | bdd-nodo02 |     | .   |     |     |     |
| ----------------------------- | --- | --- | ----------- | ---------- | --- | ---------------- | --- | ---------- | --- | --- | --- | --- | --- |
| El DELETE eliminó la fila en  |     |     |             | bdd-nodo02 |     |  (conteo = 0).   |     |            |     |     |     |     |     |
La columna  ultima_modificacion  existe en  clientes  de ambos nodos (propagada
por el ALTER TABLE en el maestro).
Los conteos de las cuatro tablas de  lab_bdd  son idénticos en nodo01 y nodo02.
| El intento de INSERT con    |     |                 |     |                          |              |  en        |            |  falla con error  |                   |            |            | .   |     |
| --------------------------- | --- | --------------- | --- | ------------------------ | ------------ | ---------- | ---------- | ----------------- | ----------------- | ---------- | ---------- | --- | --- |
|                             |     |                 |     | app_user                 |              | bdd-nodo02 |            |                   |                   |            | read-only  |     |     |
| El intento de INSERT con    |     |                 |     |                          |              |  en        |            |                   |  falla con error  |            |            | .   |     |
|                             |     |                 |     | lab_admin                |              |            | bdd-nodo02 |                   |                   |            | read-only  |     |     |
| Los snapshots               |     |                 |     |                          |  existen en  |            |            |                   |  y                |            |  y cada VM |     |     |
|                             |     | fase10-completa |     |                          |              |            | bdd-nodo01 |                   |                   | bdd-nodo02 |            |     |     |
| muestra seis snapshots con  |     |                 |     | VBoxManage snapshot list |              |            |            |                   | .                 |            |            |     |     |
Puedo explicar sin ver el documento la diferencia entre el hilo I/O y el hilo SQL
del esclavo, y qué ocurre si solo uno de los dos falla.
Puedo explicar qué es  Seconds_Behind_Master  y qué implica un valor distinto de
cero.
Puedo explicar por qué  read_only  no afecta al hilo SQL de replicación pero sí a
| app_user | .   |     |     |     |     |     |     |     |     |     |     |     |     |
| -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
26

Preguntas teóricas para estudiantes
 El parámetro log_slave_updates = ON se habilitó tanto en el maestro como en el
esclavo aunque en esta fase el esclavo no tiene ningún esclavo propio Explica en
qué escenario futuro —dentro de las fases restantes del laboratorio o en una
arquitectura real— sería indispensable que el esclavo también tenga su propio binary
log activo ¿Qué operación de administración (failover clonación auditoría) se
volvería imposible o muy difícil sin él?
 La replicación de MariaDB en este laboratorio es asíncrona Describe un escenario
concreto de fallo —no abstracto sino usando los nodos de este laboratorio— en el que
el asincronismo resulta en pérdida de datos ¿qué operación debe haberse ejecutado en
bdd-nodo01  cuándo debe fallar el nodo y qué dato concreto de lab_bdd se perdería
en bdd-nodo02 ? ¿Qué mecanismo de MariaDB (sin hardware redundante extra) mitigaría
parcialmente este riesgo?
 Compara la replicación basada en posición de archivo ( MASTER_LOG_FILE +
MASTER_LOG_POS ) con la basada en GTID ( MASTER_USE_GTID = slave_pos ) Si el
maestro rota el binary log (crea mariadb-bin.000002 ) exactamente cuando el esclavo
está leyendo el último evento de mariadb-bin.000001  ¿cómo maneja cada modalidad
esa transición? ¿Qué ventaja operacional concreta ofrece el GTID si en el futuro hay
que reapuntar el esclavo a un maestro de sustitución?
 En el esclavo read_only = ON impide escrituras de usuarios normales pero el hilo
SQL de replicación puede seguir aplicando cambios Explica bajo qué usuario interno de
MariaDB opera el hilo SQL y qué privilegios tiene que lo eximen de read_only  ¿Qué
ocurriría con la replicación si se activara super_read_only = ON en el esclavo
antes de que el hilo SQL se haya iniciado? ¿Y si se activa después de que el hilo
SQL ya está corriendo?
 El formato ROW registra las filas afectadas (imágenes antes y después del cambio) en
lugar de la sentencia SQL original Analiza las implicaciones para la sentencia
UPDATE pedidos SET total = total * 1.10 WHERE region = 'norte' si hay  pedidos
en
la región norte ¿cuántos eventos ROW generaría esta sentencia en el binlog? ¿Cómo
se compararía el tamaño del evento en formato ROW versus STATEMENT? ¿En qué
circunstancia podría el formato STATEMENT producir un resultado distinto en el esclavo
al aplicar esta misma sentencia?
Ejercicios prácticos
 Observación del binary log con mysqlbinlog 
En bdd-nodo01  ejecutar un INSERT un UPDATE y un DELETE sobre lab_bdd  Luego
usar mysqlbinlog para leer el archivo de binary log y localizar los eventos
27

Bash
sudo mysqlbinlog --base64-output=DECODE-ROWS --verbose \
/var/log/mysql/mariadb-bin.000001 | \
grep -A 20 "### INSERT\|### UPDATE\|### DELETE"
Responder ¿se ve la sentencia SQL original o los valores de columnas? ¿Puedes
identificar el server_id  el timestamp y el GTID de cada transacción? ¿Cómo
aparece el ALTER TABLE de la Prueba  en el log (como evento ROW o de otro tipo)?
Documentar los hallazgos con la salida del comando
 Simulación de fallo del hilo SQL y recuperación
En bdd-nodo02  detener únicamente el hilo SQL manteniendo el I/O activo
Bash
sudo mariadb -e "STOP SLAVE SQL_THREAD;"
En bdd-nodo01  ejecutar  INSERT en lab_bdd.clientes  Verificar que
Seconds_Behind_Master crece en bdd-nodo02 (el I/O sigue descargando pero el SQL
no aplica) Reiniciar el hilo SQL y observar cómo el lag cae a :
Bash
sudo mariadb -e "START SLAVE SQL_THREAD;"
watch -n 1 "sudo mariadb -e 'SHOW SLAVE STATUS\G' |
grep Seconds_Behind_Master"
Documentar los valores de Seconds_Behind_Master a lo largo del ejercicio y
explicar el comportamiento observado Al finalizar eliminar las  filas de prueba
con DELETE FROM lab_bdd.clientes WHERE id > 20 
 Script de verificación de consistencia maestro-esclavo
Escribir un script Bash en bdd-nodo01 que (a) inserte  filas de prueba en
lab_bdd.clientes con valores de region aleatorios distribuidos entre los cuatro
valores del ENUM (b) espere  segundos © compare automáticamente el conteo de
filas en nodo ( mysql --host=127.0.0.1 ) y en nodo ( mysql
--host=192.168.56.102 -u repl_user -p'ReplUser_2025!' ) — para esta prueba
otorgar
temporalmente el privilegio SELECT a repl_user en lab_bdd.clientes  (d) imprima
CONSISTENTE: maestro=X, esclavo=X si los conteos coinciden o DIVERGENCIA:
maestro=X, esclavo=Y si difieren Ejecutar el script y documentar el resultado
Al finalizar eliminar las filas de prueba y revocar el privilegio temporal de
repl_user 
28

Reto adicional para alumnos avanzados
Implementar el procedimiento de resincronización completa del esclavo desde cero,
aplicable cuando el esclavo se desincronizó gravemente (por ejemplo, alguien ejecutó
DROP TABLE pedidos  directamente en  bdd-nodo02  o modificó filas manualmente). El
procedimiento debe poder ejecutarse sin detener el maestro ni interrumpir a los
clientes que escriben en  bdd-nodo01 . Pasos a documentar con comandos exactos:
|  Detener los hilos de replicación en el esclavo ( |     |     | STOP SLAVE | )  |
| --------------------------------------------------- | --- | --- | ---------- | --- |
 Generar un volcado consistente del maestro con  mysqldump  incluyendo la posición
GTID del punto en que se tomó el volcado (investigar las opciones específicas de
mysqldump  de MariaDB  que registran la información GTID en el encabezado del
| archivo comparar  |                 |             |     |  y la variable de sesión |
| ------------------ | --------------- | ------------ | --- | ------------------------ |
|                    | --master-data=2 | --dump-slave |     |                          |
@@global.gtid_binlog_pos  anotada manualmente antes del volcado)
 Restaurar el volcado en el esclavo
 Reconfigurar  CHANGE MASTER TO  con la posición GTID exacta registrada en el paso 
 Iniciar los hilos de replicación y verificar con  SHOW SLAVE STATUS\G  que ambos
| hilos muestran  |  el lag es  |  y               |  está vacío |     |
| --------------- | ------------ | ---------------- | ------------ | --- |
| Yes             |              | 0 Last_SQL_Error |              |     |
Incluir en la entrega: los comandos exactos con su salida, el razonamiento técnico de
cada decisión (en particular, por qué se usa  --single-transaction  y qué garantía
ofrece), y la diferencia entre resincronizar desde un volcado   versus desde
mysqldump
| un snapshot de VirtualBox del nodo01 en  |     | fase08-completa |     | .   |
| ---------------------------------------- | --- | --------------- | --- | --- |
29

Criterios de evaluación para el profesor
| Criterio | Peso | Indicador de logro |     |     |     |
| -------- | ---- | ------------------ | --- | --- | --- |
Configuración del maestro % SHOW VARIABLES  confirma  log_bin=ON 
|     |     | binlog_format=ROW |                          | server_id=1         |    |
| --- | --- | ----------------- | ------------------------- | ------------------- | --- |
|     |     | gtid_domain_id=1  |                          | 60-replication-     |     |
|     |     | master.cnf        |  existe con el contenido  |                     |     |
|     |     | correcto         | repl_user                 |  tiene exactamente  |     |
 para la IP
REPLICATION SLAVE ON *.*
correcta del esclavo
Configuración del esclavo % SHOW VARIABLES  confirma  server_id=2 
|     |     | read_only=ON           |   60-replication-          |                 |     |
| --- | --- | ---------------------- | --------------------------- | --------------- | --- |
|     |     | slave.cnf              |  existe  SHOW SLAVE STATUS |                 |     |
|     |     | muestra                | Slave_IO_Running: Yes       |                 |    |
|     |     | Slave_SQL_Running: Yes |                             |   Using_Gtid:  |     |
Slave_Pos
Pruebas de propagación % El estudiante ejecuta y documenta las
cinco pruebas (INSERT UPDATE DELETE
DDL conteo global) y muestra evidencia
de que cada cambio en el maestro se
reflejó en el esclavo puede presentar los
resultados de ambos nodos
simultáneamente
| Verificación de  | % | Se demuestra con evidencia del mensaje  |     |     |     |
| ---------------- | --- | --------------------------------------- | --- | --- | --- |
read_only
de error que usuarios sin SUPER no
pueden escribir en el esclavo el
estudiante explica por qué el hilo SQL es
|     |     | la excepción y el usuario  |     | root  también lo  |     |
| --- | --- | -------------------------- | --- | ----------------- | --- |
es
Comprensión conceptual  % Las respuestas demuestran comprensión
| (preguntas teóricas) |     | de los hilos de replicación GTID vs  |     |           |     |
| -------------------- | --- | -------------------------------------- | --- | --------- | --- |
|                      |     | file+pos asincronismo y               |     | read_only |     |
usando terminología técnica precisa con
ejemplos del propio laboratorio
Snapshots y documentación % Los snapshots  fase10-completa  existen
en ambos nodos con descripciones
informativas el estudiante puede listar los
seis snapshots de cada VM con
VBoxManage snapshot list
Preparación para la siguiente fase
La Fase 11: Replicación Lógica (Multi-Maestro con  bdd-nodo03 ) requerirá:
30

• La replicación física entre bdd-nodo01 y bdd-nodo02 funcionando correctamente
(esta fase) con snapshots fase10-completa tomados en ambos nodos
• Comprensión sólida de GTID y binary log la Fase  reutilizará exactamente los
mismos conceptos pero en una topología bidireccional donde nodo actúa como maestro
simultáneo de nodo
• Creación de bdd-nodo03  será la primera VM nueva del laboratorio desde la
Fase  Se creará como un clon enlazado (linked clone) de bdd-nodo01 tomado
del snapshot fase08-completa —que tiene lab_bdd instalado pero sin configuración
de replicación— y se le asignará la IP 192.168.56.103 y el hostname bdd-nodo03 
El procedimiento de clonación y configuración inicial del nuevo nodo se hará
íntegramente al inicio de la Fase 
• El Documento de Diseño Distribuido ( fase09-disenyo-distribuido.md  sección )
como referencia define que nodo tendrá el esquema lab_bdd completo y
replicación bidireccional con nodo
No es necesario instalar, configurar ni crear nada adicional ahora.
31

Fase 11 — Replicación Lógica Multi-
Maestro con MariaDB Galera Cluster
Continuación directa de la Fase 10. bdd-nodo01 opera como maestro de replicación física y
bdd-nodo02 como esclavo con read_only = ON ; el snapshot fase10-completa fue
tomado en ambos nodos. Esta fase introduce la replicación lógica multi-maestro mediante
MariaDB Galera Cluster: los tres nodos se convierten en pares iguales que aceptan lecturas
y escrituras simultáneamente con garantías de consistencia síncrona. Se crea bdd-nodo03 ,
se instala la librería Galera en los tres nodos, se migra la topología de la Fase 10 y se
verifican el comportamiento multi-maestro, la detección automática de conflictos y la
recuperación ante la caída de un nodo. Esta fase no introduce fragmentación de datos (eso
corresponde a la Fase 13): los tres nodos mantienen una copia completa e idéntica de
lab_bdd .
A. Objetivos de aprendizaje
Al finalizar esta fase, el estudiante será capaz de:
 Distinguir con precisión la replicación asíncrona (Fase ) de la replicación síncrona por
certificación de Galera explicando las implicaciones de cada modelo para consistencia y
disponibilidad según el teorema CAP
 Explicar qué es un write-set en qué consiste la certificación de transacciones en Galera y
por qué este mecanismo puede detectar conflictos que la replicación asíncrona no puede
 Crear y configurar bdd-nodo03 a partir de un clon de un nodo existente ajustando los
parámetros que identifican de forma única a cada miembro del clúster
 Instalar la librería galera-4 y definir los parámetros wsrep esenciales en los tres nodos
del laboratorio
 Inicializar un clúster Galera mediante la operación de bootstrap y unir los nodos restantes
usando SST (State Snapshot Transfer)
 Ejecutar escrituras en cualquier nodo del clúster y verificar que se propagan
sincrónicamente a los demás nodos demostrando el comportamiento multi-
maestro genuino
 Forzar un escenario de conflicto (dos transacciones que modifican la misma fila en
distintos nodos simultáneamente) y observar cómo Galera resuelve el conflicto con el
rollback automático de la transacción perdedora
 Simular la caída y recuperación de un nodo interpretar los indicadores
wsrep_cluster_size y wsrep_cluster_status  y verificar que el nodo recuperado
obtiene los datos que le faltaban sin intervención manual
1

 Cerrar la fase con el snapshot fase11-completa en los tres nodos en el estado de mayor
preparación alcanzado hasta ahora
B. Conceptos teóricos necesarios
1. Replicación asíncrona vs. síncrona: el compromiso CAP en la práctica.
En la Fase 10 se implementó replicación asíncrona: el maestro confirma ( COMMIT ) la
transacción al cliente antes de que el esclavo la haya aplicado. El esclavo puede quedar
rezagado. Si el maestro cae en ese instante, el esclavo puede no tener los últimos cambios —
esto es pérdida de datos aceptada a cambio de mayor disponibilidad. Esta es la postura AP
del teorema CAP: disponibilidad sobre consistencia ante partición.
Galera implementa replicación síncrona por certificación: antes de que el COMMIT se
confirme al cliente, el nodo que originó la transacción envía su write-set a todos los demás
nodos y espera que todos lo certifiquen. Solo cuando todos confirman que no hay conflicto se
confirma la transacción. Esta es la postura CP: todos los nodos siempre tienen los mismos
datos, pero un nodo que pierde contacto con el clúster deja de aceptar escrituras hasta
recuperar la comunicación.
2. El protocolo wsrep y los write-sets.
wsrep (Write-Set REPlication) es una interfaz estándar que MariaDB expone y que la librería
Galera implementa. El flujo de una transacción con wsrep es:
Text
Cliente → BEGIN en nodo01
Cliente → INSERT / UPDATE / DELETE (se ejecuta localmente en memoria)
Cliente → COMMIT
↓
nodo01 serializa los cambios como write-set:
{ primary_keys_afectadas | valores_nuevos | número_de_secuencia_global
(seqno) }
↓
nodo01 difunde el write-set a nodo02 y nodo03 (broadcast)
↓
CADA NODO certifica: ¿algún write-set anterior en vuelo toca las
mismas PKs?
↓ NO → certificación exitosa → COMMIT aplicado en todos los nodos
↓ SÍ → conflicto → el write-set con seqno menor gana;
el otro recibe ROLLBACK automático
2

La ventaja clave es que la certificación no requiere comunicación durante la ejecución de la
transacción — solo en el momento del COMMIT . Esto minimiza la penalización de latencia a una
sola ronda de red por transacción.
3. SST e IST: cómo un nodo nuevo o recuperado obtiene datos.
Cuando un nodo se une al clúster (o vuelve tras estar offline), necesita sincronizarse:
• SST (State Snapshot Transfer) copia completa del estado actual del nodo donante al
nodo solicitante (joiner) El método rsync copia los archivos de datos directamente y es el
más simple mariabackup es no bloqueante y se recomienda en producción Se usa
cuando el nodo joiner está completamente desactualizado o es nuevo
• IST (Incremental State Transfer) solo transfiere los write-sets que el joiner no tiene
usando el gcache (caché en disco de write-sets recientes) Se usa cuando el nodo estuvo
offline poco tiempo y los write-sets faltantes aún están en el gcache Es mucho más rápido
que SST
El clúster elige automáticamente SST o IST según el estado del nodo que se une.
4. Componente Primario y quórum.
Galera usa el concepto de Componente Primario (PC): la partición del clúster que tiene
quórum ( n/2 + 1 nodos). Solo la PC puede procesar transacciones. Si la red se divide en dos
particiones, la que tenga mayoría de nodos continúa como PC; la minoría entra en estado non-
Primary y rechaza todas las escrituras.
Para un clúster de 3 nodos:
• Quórum =  nodos
• Si cae  nodo → los  restantes mantienen el quórum y siguen operando
• Si caen  nodos → el nodo restante queda solo pierde quórum y entra en non-Primary
(no acepta escrituras) Esto es intencional se prefiere detener al nodo antes que aceptar
datos que podrían no ser consistentes con el resto del clúster cuando este se recupere
5. El problema del split-brain.
Si una partición de red divide el clúster en dos mitades exactamente iguales, ambas podrían
creer que son la PC, aceptar escrituras incompatibles y producir divergencia de datos — el
split-brain. Un clúster de número impar de nodos (3, 5, 7…) nunca produce empate, razón
fundamental por la que Galera se opera con 3 nodos mínimo. Un clúster de 2 nodos puede
complementarse con un árbitro ligero ( garbd ) que ocupa el tercer “voto” de quórum sin
almacenar datos.
3

6. auto_increment en multi-maestro: prevención de colisiones de clave primaria.
Si dos nodos generan simultáneamente el valor AUTO_INCREMENT siguiente, podrían producir el
mismo número. Galera resuelve esto con wsrep_auto_increment_control = ON (activado por
defecto), que ajusta automáticamente dos variables en todos los nodos:
• auto_increment_increment = N (donde N = número de nodos del clúster) cada nodo
avanza de N en N
• auto_increment_offset = [1, 2, 3, ...] según el número de secuencia del nodo
Con 3 nodos: nodo01 genera 1, 4, 7, ... ; nodo02 genera 2, 5, 8, ... ; nodo03 genera
3, 6, 9, ... . Nunca habrá colisiones de PK aunque dos nodos inserten al mismo tiempo.
7. Galera y el binary log: coexistencia con replicación asíncrona downstream.
Un clúster Galera puede mantener el binary log activo en uno o todos sus nodos. Esto permite
añadir esclavos asíncronos tradicionales apuntando a cualquier miembro del clúster —
arquitectura conocida como Galera + async slave — que se usa para offloading de respaldos o
replicación geográfica. En este laboratorio el binary log de nodo01 (activo desde la Fase 10) se
conserva con este propósito didáctico.
8. Contraste entre replicación “física” (Fase 10) y “lógica” (Fase 11).
Aspecto Fase  — Física (binlog Fase  — Lógica (Galera wsrep)
row-based)
Unidad de replicación Evento de fila binario Write-set (PKs afectadas + valores
(imagen antes/después) + seqno)
Sincronía Asíncrona Síncrona por certificación
Topología Maestro → esclavo Todos los nodos son pares iguales
(unidireccional)
Escrituras Solo en el maestro En cualquier nodo
Detección de conflictos No (divergencia Automática rollback determinista
silenciosa posible)
Postura CAP AP (disponibilidad ante CP (consistencia ante partición)
partición)
Implementación en log_bin  CHANGE MASTER wsrep_on = ON  galera_new_cluster
MariaDB TO  START SLAVE
4

C. Arquitectura utilizada
La arquitectura final de esta fase integra tres nodos Galera en la misma red Host-Only:
| Nodo | Hostname | IP  | Rol en Galera | ¿Acepta  |
| ---- | -------- | --- | ------------- | -------- |
escrituras?
|    | bdd-nodo01 |  | Nodo Galera   | Sí  |
| --- | ---------- | ------------- | -------------- | --- |
|     |            |              | (bootstrapper  |     |
inicial)
|    | bdd-nodo02 |  | Nodo Galera    | Sí  |
| --- | ---------- | ------------- | --------------- | --- |
|     |            |              | (joiner)        |     |
|    | bdd-nodo03 |  | Nodo Galera    | Sí  |
|     |            |              | (joiner nuevo) |     |
El término “bootstrapper” indica únicamente qué nodo inicializa el clúster en el primer
arranque. En operación normal los tres nodos son pares completamente iguales: no existe
un maestro, no existe un esclavo.
5

D. Procedimiento paso a paso
Paso 1 — Crear bdd-nodo03 como clon enlazado de bdd-nodo01 .
Clonar la VM bdd-nodo01 desde el snapshot fase09-completa (estado previo a la
configuración de replicación física), que proporciona una base limpia con Ubuntu Server,
MariaDB 10.11 y el esquema lab_bdd sin configuración de maestro ni esclavo.
Paso 2 — Personalizar bdd-nodo03 : hostname, IP y server_id .
Cambiar el hostname a bdd-nodo03 , la IP estática a 192.168.56.103 y el server_id de
MariaDB a 3 . Actualizar el archivo /etc/hosts en los tres nodos para incluir los nombres de
los tres miembros.
Paso 3 — Instalar la librería Galera en los tres nodos.
Instalar el paquete galera-4 que provee la librería libgalera_smm.so requerida por MariaDB
para el protocolo wsrep.
Paso 4 — Limpiar la configuración de esclavo de la Fase 10 en bdd-nodo02 .
Detener el agente esclavo, ejecutar RESET SLAVE ALL y eliminar read_only = ON del archivo
de configuración. bdd-nodo02 pasa de esclavo a par Galera.
Paso 5 — Crear el archivo de configuración Galera en cada nodo.
Crear /etc/mysql/mariadb.conf.d/61-galera.cnf en los tres nodos con los parámetros
wsrep necesarios, diferenciando únicamente wsrep_node_address y wsrep_node_name en
cada uno.
Paso 6 — Inicializar el clúster (bootstrap desde bdd-nodo01 ).
Detener MariaDB en nodo01 y arrancar el clúster con galera_new_cluster . En este momento
existe un clúster de un solo nodo en estado Primary.
Paso 7 — Unir bdd-nodo02 al clúster.
Arrancar MariaDB en nodo02 con systemctl start mariadb . Galera detecta el clúster
existente, solicita SST y se sincroniza automáticamente.
Paso 8 — Unir bdd-nodo03 al clúster.
Igual que el paso anterior: arrancar MariaDB en nodo03 y verificar la sincronización.
Paso 9 — Verificar el estado completo del clúster.
Consultar las variables wsrep_* en los tres nodos para confirmar: wsrep_cluster_size = 3 ,
wsrep_cluster_status = Primary , wsrep_local_state_comment = Synced en todos.
Paso 10 — Demostrar escrituras multi-maestro.
Insertar registros en nodo01 y verificar su presencia inmediata en nodo02 y nodo03. Insertar
en nodo03 y verificar en nodo01 y nodo02.
6

Paso 11 — Demostrar la detección de conflictos.
Abrir dos sesiones simultáneas, una en nodo01 y otra en nodo03, que modifiquen la misma fila.
Observar el rollback automático de la transacción perdedora y verificar que todos los nodos
ven el mismo resultado final (determinismo Galera).
Paso 12 — Simular caída y recuperación automática de un nodo.
Detener bruscamente nodo02, insertar datos con el clúster en estado de 2 nodos, reiniciar
nodo02 y verificar que recuperó los datos faltantes por IST sin intervención manual.
Paso 13 — Apagar los tres nodos ordenadamente y tomar snapshots.
E. Comandos completos
Los comandos marcados (host) se ejecutan en PowerShell en Windows. Los marcados (VM
— nodoXX) se ejecutan en SSH dentro del nodo indicado. Los bloques SQL dentro de sudo
mariadb se pueden pegar directamente en el prompt del motor.
7

E.1 Crear bdd-nodo03 como clon de bdd-nodo01 (host)
PowerShell
# Verificar que todas las VMs relevantes están apagadas antes de clonar
VBoxManage list runningvms
# Clonar bdd-nodo01 desde el snapshot fase09-completa
# --options link crea un clon enlazado (usa el disco base del snapshot
de origen;
# solo ocupa espacio para los cambios diferenciales). Omitir --options
link para
# un clon completo e independiente (tarda más y ocupa más disco).
VBoxManage clonevm "bdd-nodo01" `
--snapshot "fase09-completa" `
--options link `
--name "bdd-nodo03" `
--basefolder "C:\LabBDD\VMs" `
--register
# Confirmar que bdd-nodo03 aparece en la lista de VMs
VBoxManage list vms | Select-String "bdd-nodo03"
# Verificar que el adaptador de red del clon es Host-Only
VBoxManage showvminfo "bdd-nodo03" | Select-String "NIC 1"
# Si el adaptador no está configurado correctamente:
VBoxManage modifyvm "bdd-nodo03" `
--nic1 hostonly `
--hostonlyadapter1 "VirtualBox Host-Only Ethernet Adapter"
¿Por qué fase09-completa y no fase10-completa ? El snapshot fase09-completa
contiene el esquema lab_bdd correctamente poblado (Fase 8) sin la configuración de
maestro de la Fase 10, lo que da a nodo03 una base completamente neutra para configurar
Galera desde cero.
E.2 Iniciar bdd-nodo03 y cambiar hostname e IP (host + VM — nodo03)
Arrancar nodo03 en modo headless:
PowerShell
VBoxManage startvm "bdd-nodo03" --type headless
El clon hereda la IP 192.168.56.101 de nodo01, lo que provoca conflicto de IP. Acceder por la
consola de VirtualBox (no por SSH todavía): en VirtualBox Manager, seleccionar bdd-nodo03
→ botón Mostrar (Show). Iniciar sesión con las credenciales de bddadmin .
8

Dentro de bdd-nodo03 (consola VirtualBox):
Bash
# ---- Cambiar hostname ----
sudo hostnamectl set-hostname bdd-nodo03
# ---- Identificar nombre de la interfaz de red ----
ip link show
# Normalmente: enp0s3 o enp0s8 (heredado del clon)
# ---- Cambiar la IP estática en Netplan ----
# El nombre del archivo puede variar; listar para encontrarlo:
ls /etc/netplan/
sudo nano /etc/netplan/00-installer-config.yaml
Contenido del archivo (ajustar el nombre de interfaz si difiere):
YAML
network:
version: 2
ethernets:
enp0s3:
dhcp4: false
addresses:
- 192.168.56.103/24
routes:
- to: default
via: 192.168.56.1
nameservers:
addresses:
- 8.8.8.8
- 8.8.4.4
Aplicar la configuración de red:
Bash
sudo netplan apply
# Verificar la nueva IP
ip addr show
hostname
9

La interfaz debe mostrar 192.168.56.103 y el hostname debe ser bdd-nodo03 . Desde este
momento SSH funciona desde el host:
PowerShell
# Verificar desde el host
ssh bddadmin@192.168.56.103
E.3 Configurar /etc/hosts y server_id en bdd-nodo03 (VM — nodo03)
Bash
# Actualizar /etc/hosts para que el nodo conozca a todos los miembros
del clúster
sudo tee /etc/hosts > /dev/null << 'EOF'
127.0.0.1 localhost
127.0.1.1 bdd-nodo03
# Laboratorio BDD — clúster Galera
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
192.168.56.103 bdd-nodo03
EOF
# Verificar conectividad de red hacia los otros nodos
ping -c 3 192.168.56.101
ping -c 3 192.168.56.102
Cambiar el server_id de MariaDB a 3 (debe ser único en el clúster). El archivo de
configuración de replicación se creó en la Fase 10; si no existe, crearlo:
Bash
# Verificar si existe el archivo de configuración de la Fase 10
ls /etc/mysql/mariadb.conf.d/60-replication.cnf
# Editar (o crear) el archivo para establecer server_id = 3
sudo nano /etc/mysql/mariadb.conf.d/60-replication.cnf
El archivo debe contener como mínimo:
10

Text
[mariadb]
server_id = 3
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
Guardar, reiniciar MariaDB y confirmar el server_id :
Bash
sudo systemctl restart mariadb
sudo mariadb -e "SELECT @@server_id AS server_id;"
La salida debe mostrar 3 .
E.4 Actualizar /etc/hosts en bdd-nodo01 y bdd-nodo02 (VM — nodo01 y
nodo02)
Ejecutar en cada uno de los dos nodos existentes:
Bash
# Ajustar la segunda línea (127.0.1.1) según el hostname del nodo actual
sudo tee /etc/hosts > /dev/null << 'EOF'
127.0.0.1 localhost
127.0.1.1 bdd-nodo01
# Laboratorio BDD — clúster Galera
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
192.168.56.103 bdd-nodo03
EOF
En bdd-nodo02 , cambiar la segunda línea a 127.0.1.1 bdd-nodo02 .
Verificar resolución de nombres:
11

Bash
ping -c 2 bdd-nodo03
E.5 Instalar la librería Galera en los tres nodos (VM — nodo01,
nodo02, nodo03)
Ejecutar en cada uno de los tres nodos (en tres terminales SSH simultáneas):
Bash
# Actualizar lista de paquetes
sudo apt update
# Instalar la librería Galera 4
# En sistemas con MariaDB del repositorio oficial, galera-4 puede
# ya estar instalado como dependencia de mariadb-server.
sudo apt install -y galera-4
# Verificar que la librería existe en la ruta estándar
ls -lh /usr/lib/galera/libgalera_smm.so
Si el archivo no está en /usr/lib/galera/ , ubicarlo con:
Bash
find /usr -name "libgalera_smm.so" 2>/dev/null
Registrar la ruta exacta — se usará en el parámetro wsrep_provider del siguiente paso.
12

E.6 Limpiar la configuración de esclavo de la Fase 10 en bdd-nodo02 (VM
— nodo02)
Bash
sudo mariadb << 'EOF'
-- Ver el estado actual del esclavo (documentar antes de eliminar)
SHOW SLAVE STATUS\G
-- Detener el agente de replicación esclavo
STOP SLAVE;
-- Eliminar TODA la configuración de esclavo (master.info, relay-log.info)
RESET SLAVE ALL;
-- Confirmar que ya no hay configuración activa
SHOW SLAVE STATUS\G
EOF
La última instrucción SHOW SLAVE STATUS\G debe devolver un conjunto vacío.
Eliminar también el parámetro read_only del archivo de configuración:
Bash
sudo nano /etc/mysql/mariadb.conf.d/60-replication.cnf
Asegurarse de que el archivo contenga únicamente:
Text
[mariadb]
server_id = 2
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
# (sin read_only = ON)
No reiniciar MariaDB todavía; se hará al aplicar la configuración Galera en E.9.
13

E.7 Crear el archivo de configuración Galera en bdd-nodo01 (VM —
nodo01)
Bash
sudo tee /etc/mysql/mariadb.conf.d/61-galera.cnf > /dev/null << 'EOF'
# ================================================================
# Configuración Galera Cluster — bdd-nodo01
# Creado en la Fase 11.
# Cargado después de 60-replication.cnf (que ya
establece binlog_format=ROW).
# ================================================================
[mariadb]
# ---- Activar el protocolo wsrep ----
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_provider_options = "pc.recovery=YES; gcache.size=256M"
# ---- Identificación del clúster ----
wsrep_cluster_name = lab_bdd_cluster
wsrep_cluster_address =
gcomm://192.168.56.101,192.168.56.102,192.168.56.103
# ---- Identificación de este nodo ----
wsrep_node_address = 192.168.56.101
wsrep_node_name = bdd-nodo01
# ---- Método de sincronización inicial (SST) ----
# rsync: simple, adecuado para este laboratorio.
# Alternativa de producción: wsrep_sst_method = mariabackup
wsrep_sst_method = rsync
# ---- Hilos para aplicar write-sets recibidos ----
wsrep_slave_threads = 4
# ---- Requerimiento de InnoDB para Galera ----
# innodb_autoinc_lock_mode=2: necesario para auto_increment en
multi-maestro
innodb_autoinc_lock_mode = 2
# ---- Control automático de auto_increment para evitar colisiones de PK -
---
wsrep_auto_increment_control = ON
# Nota: binlog_format = ROW ya está definido en 60-replication.cnf.
# Galera requiere ROW; no duplicar aquí para evitar advertencias
de conflicto.
EOF
# Verificar que no hay errores de sintaxis
cat /etc/mysql/mariadb.conf.d/61-galera.cnf
14

E.8 Crear el archivo de configuración Galera en bdd-nodo02 (VM —
nodo02)
Bash
sudo tee /etc/mysql/mariadb.conf.d/61-galera.cnf > /dev/null << 'EOF'
# ================================================================
# Configuración Galera Cluster — bdd-nodo02
# Creado en la Fase 11.
# ================================================================
[mariadb]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_provider_options = "pc.recovery=YES; gcache.size=256M"
wsrep_cluster_name = lab_bdd_cluster
wsrep_cluster_address =
gcomm://192.168.56.101,192.168.56.102,192.168.56.103
# ---- Solo estas dos líneas difieren de nodo01 ----
wsrep_node_address = 192.168.56.102
wsrep_node_name = bdd-nodo02
wsrep_sst_method = rsync
wsrep_slave_threads = 4
innodb_autoinc_lock_mode = 2
wsrep_auto_increment_control = ON
EOF
15

E.9 Crear el archivo de configuración Galera en bdd-nodo03 (VM —
nodo03)
Bash
sudo tee /etc/mysql/mariadb.conf.d/61-galera.cnf > /dev/null << 'EOF'
# ================================================================
# Configuración Galera Cluster — bdd-nodo03
# Creado en la Fase 11.
# ================================================================
[mariadb]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_provider_options = "pc.recovery=YES; gcache.size=256M"
wsrep_cluster_name = lab_bdd_cluster
wsrep_cluster_address =
gcomm://192.168.56.101,192.168.56.102,192.168.56.103
# ---- Solo estas dos líneas difieren de nodo01 ----
wsrep_node_address = 192.168.56.103
wsrep_node_name = bdd-nodo03
wsrep_sst_method = rsync
wsrep_slave_threads = 4
innodb_autoinc_lock_mode = 2
wsrep_auto_increment_control = ON
EOF
E.10 Verificar y abrir puertos Galera si el firewall está activo (VM — los
tres nodos)
Bash
# Comprobar si ufw está activo (Ubuntu 24.04 lo instala pero inactivo
por defecto)
sudo ufw status
# Si el resultado es "Status: inactive" no se necesita hacer nada.
# Si está activo, abrir los puertos Galera en CADA nodo:
sudo ufw allow 3306/tcp comment 'MariaDB cliente'
sudo ufw allow 4567/tcp comment 'Galera cluster wsrep'
sudo ufw allow 4567/udp comment 'Galera cluster wsrep UDP'
sudo ufw allow 4568/tcp comment 'Galera IST'
sudo ufw allow 4444/tcp comment 'Galera SST rsync'
sudo ufw reload
16

E.11 Inicializar el clúster — Bootstrap desde bdd-nodo01 (VM — nodo01)
Bash
# Detener el servicio MariaDB estándar
sudo systemctl stop mariadb
# Inicializar el clúster Galera.
# galera_new_cluster arranca MariaDB con wsrep_cluster_address='gcomm://'
# (cadena vacía), señal para Galera de que este nodo es el primero
del clúster
# y debe inicializarlo con un nuevo UUID de clúster.
sudo galera_new_cluster
# Verificar que el servicio arrancó correctamente
sudo systemctl status mariadb --no-pager
Verificar el estado del clúster en nodo01 (en este punto solo hay 1 nodo):
Bash
sudo mariadb -e "
SHOW STATUS WHERE Variable_name IN (
'wsrep_cluster_size',
'wsrep_cluster_status',
'wsrep_connected',
'wsrep_ready',
'wsrep_local_state_comment',
'wsrep_node_name'
);
"
Salida esperada:
17

Text
+---------------------------+------------+
| Variable_name | Value |
+---------------------------+------------+
| wsrep_cluster_size | 1 |
| wsrep_cluster_status | Primary |
| wsrep_connected | ON |
| wsrep_ready | ON |
| wsrep_local_state_comment | Synced |
| wsrep_node_name | bdd-nodo01 |
+---------------------------+------------+
Alternativa:
SQL
SELECT 'wsrep_node_name' AS Variable_name,
@@wsrep_node_name AS Value
UNION ALL
SELECT VARIABLE_NAME, VARIABLE_VALUE
FROM information_schema.GLOBAL_STATUS
WHERE VARIABLE_NAME IN (
'WSREP_CLUSTER_SIZE',
'WSREP_CLUSTER_STATUS',
'WSREP_CONNECTED',
'WSREP_READY',
'WSREP_LOCAL_STATE_COMMENT'
);
Salida esperada:
18

Text
+---------------------------+------------+
| Variable_name | Value |
+---------------------------+------------+
| wsrep_node_name | bdd-nodo01 |
| WSREP_LOCAL_STATE_COMMENT | Synced |
| WSREP_CLUSTER_SIZE | 1 |
| WSREP_CLUSTER_STATUS | Primary |
| WSREP_CONNECTED | ON |
| WSREP_READY | ON |
+---------------------------+------------+
wsrep_cluster_size = 1 es correcto en este punto: solo nodo01 está en el clúster. Un
valor de wsrep_cluster_status = Primary con un solo nodo es normal y esperado
durante el bootstrap.
E.12 Unir bdd-nodo02 al clúster (VM — nodo02)
Bash
# Arrancar MariaDB normalmente (NO usar galera_new_cluster —
# ese comando crea un clúster nuevo; aquí queremos UNIRSE al existente).
sudo systemctl start mariadb
# Observar el log en tiempo real durante el SST (puede tardar 30-120 s)
sudo journalctl -u mariadb -f --no-pager | grep -
E "WSREP|SST|Synced|state"
# Ctrl+C para salir cuando aparezca "WSREP: Synchronized with group"
Verificar que nodo02 se unió correctamente:
19

Bash
sudo mariadb -e "
SHOW STATUS WHERE Variable_name IN (
'wsrep_cluster_size',
'wsrep_cluster_status',
'wsrep_local_state_comment',
'wsrep_node_name'
);
"
Salida esperada en nodo02:
Text
+---------------------------+------------+
| Variable_name | Value |
+---------------------------+------------+
| wsrep_cluster_size | 2 |
| wsrep_cluster_status | Primary |
| wsrep_local_state_comment | Synced |
| wsrep_node_name | bdd-nodo02 |
+---------------------------+------------+
Confirmar desde nodo01 que el clúster creció:
Bash
# En bdd-nodo01
sudo mariadb -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
E.13 Unir bdd-nodo03 al clúster (VM — nodo03)
Bash
sudo systemctl start mariadb
# Monitorear el progreso del SST
sudo journalctl -u mariadb -f --no-pager | grep -E "WSREP|SST|IST|Synced"
# Ctrl+C al aparecer "Synchronized with group"
20

Verificar el estado final:
Bash
sudo mariadb -e "
SHOW STATUS WHERE Variable_name IN (
'wsrep_cluster_size',
'wsrep_cluster_status',
'wsrep_local_state_comment',
'wsrep_node_name'
);
"
Salida esperada en nodo03:
Text
+---------------------------+------------+
| Variable_name | Value |
+---------------------------+------------+
| wsrep_cluster_size | 3 |
| wsrep_cluster_status | Primary |
| wsrep_local_state_comment | Synced |
| wsrep_node_name | bdd-nodo03 |
+---------------------------+------------+
E.14 Verificación completa del estado del clúster en los tres nodos (VM)
Ejecutar en cada uno de los tres nodos:
21

Bash
sudo mariadb << 'EOF'
-- Estado global del clúster
SELECT VARIABLE_NAME, VARIABLE_VALUE AS valor
FROM information_schema.GLOBAL_STATUS
WHERE VARIABLE_NAME IN (
'WSREP_CLUSTER_SIZE',
'WSREP_CLUSTER_STATUS',
'WSREP_CONNECTED',
'WSREP_READY',
'WSREP_LOCAL_STATE_COMMENT',
'WSREP_NODE_NAME',
'WSREP_FLOW_CONTROL_PAUSED',
'WSREP_CERT_DEPS_DISTANCE'
)
ORDER BY VARIABLE_NAME;
-- Miembros actuales del clúster (tabla disponible solo con Galera activo)
SELECT * FROM information_schema.WSREP_MEMBERSHIP
ORDER BY INDEX;
-- Verificar que auto_increment fue ajustado automáticamente por Galera
SHOW VARIABLES LIKE 'auto_increment_increment';
SHOW VARIABLES LIKE 'auto_increment_offset';
-- Confirmar que lab_bdd tiene los datos correctos
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM
lab_bdd.clientes UNION ALL
SELECT 'productos', COUNT(*) FROM
lab_bdd.productos UNION ALL
SELECT 'pedidos', COUNT(*) FROM
lab_bdd.pedidos UNION ALL
SELECT 'detalle_pedidos', COUNT(*) FROM
lab_bdd.detalle_pedidos;
EOF
information_schema.WSREP_MEMBERSHIP debe mostrar exactamente 3 filas con los
nombres bdd-nodo01 , bdd-nodo02 , bdd-nodo03 , sus IPs y estado Synced . Esta tabla solo
existe cuando Galera está activo.
E.15 Demostrar escrituras multi-maestro (VM — nodo01 y nodo03)
Prueba A: escritura en nodo01, lectura inmediata en nodo02 y nodo03.
En bdd-nodo01 :
22

Bash
sudo mariadb lab_bdd << 'EOF'
INSERT INTO clientes (nombre, apellido, email, telefono, region, ciudad)
VALUES ('Prueba', 'GaleraA', 'prueba.galera.a@lab.test',
'5500000021', 'norte', 'Ciudad de México');
SELECT id, nombre, apellido, email FROM clientes
WHERE email = 'prueba.galera.a@lab.test';
EOF
Verificar inmediatamente en nodo02 y nodo03 (la replicación es síncrona — no hay lag):
Bash
# Ejecutar en bdd-nodo02 Y en bdd-nodo03
sudo mariadb lab_bdd -e "
SELECT id, nombre, apellido, email, ciudad
FROM clientes WHERE email = 'prueba.galera.a@lab.test';
"
El registro debe aparecer en los tres nodos con el mismo id .
Prueba B: escritura directamente en nodo03.
Bash
# En bdd-nodo03
sudo mariadb lab_bdd << 'EOF'
INSERT INTO clientes (nombre, apellido, email, telefono, region, ciudad)
VALUES ('Prueba', 'GaleraC', 'prueba.galera.c@lab.test',
'5500000022', 'sur', 'Guadalajara');
SELECT id, nombre, apellido, email FROM clientes
WHERE email = 'prueba.galera.c@lab.test';
EOF
Verificar en nodo01 y nodo02:
23

Bash
# En bdd-nodo01 Y en bdd-nodo02
sudo mariadb lab_bdd -e "
SELECT id, nombre, apellido, email
FROM clientes WHERE email LIKE 'prueba.galera.%'
ORDER BY id;
"
Ambos registros ( .a y .c ) deben aparecer en los tres nodos. Verificar también el incremento
automático de PK por nodo:
Bash
# En cualquier nodo
sudo mariadb -e "
SHOW VARIABLES LIKE 'auto_increment_increment';
SHOW VARIABLES LIKE 'auto_increment_offset';
"
Con un clúster de 3 nodos y wsrep_auto_increment_control = ON , la salida típica muestra
auto_increment_increment = 3 . El offset varía: 1 en nodo01, 2 en nodo02, 3 en nodo03.
E.16 Demostrar detección de conflictos (VM — nodo01 y
nodo03 simultáneamente)
Este experimento requiere dos terminales SSH abiertas al mismo tiempo: una a nodo01 y otra
a nodo03.
Preparar la fila de prueba:
Bash
# En cualquier nodo — identificar la fila que se usará
sudo mariadb lab_bdd -e "SELECT id, nombre, ciudad FROM clientes WHERE id
= 1;"
Terminal A — sesión en nodo01 (iniciar primero):
24

Bash
sudo mariadb lab_bdd
Dentro del prompt de MariaDB en nodo01:
SQL
-- La transacción modifica la fila id=1 localmente y luego espera
10 segundos
-- antes de intentar COMMIT; ese tiempo es la ventana para que
nodo03 cometa.
START TRANSACTION;
UPDATE clientes SET ciudad = 'Ciudad_desde_nodo01' WHERE id = 1;
SELECT SLEEP(10);
COMMIT;
Terminal B — sesión en nodo03 (ejecutar MIENTRAS el SLEEP corre en Terminal A):
Bash
sudo mariadb lab_bdd << 'EOF'
-- Nodo03 modifica la misma fila y confirma ANTES de que nodo01 salga
del SLEEP
START TRANSACTION;
UPDATE clientes SET ciudad = 'Ciudad_desde_nodo03' WHERE id = 1;
COMMIT;
-- Esta transacción debe TENER ÉXITO (se certifica primero)
SELECT 'Transaccion nodo03: EXITOSA' AS resultado;
EOF
Resultado esperado: la sesión en nodo01 recibirá un error similar a:
Text
ERROR 1213 (40001): Deadlock found when trying to get lock;
try restarting transaction
Verificar que todos los nodos tienen el mismo valor final (determinismo de Galera):
25

Bash
# En los TRES nodos — deben devolver EXACTAMENTE el mismo resultado
sudo mariadb lab_bdd -e "SELECT id, nombre, ciudad FROM clientes WHERE id
= 1;"
Solo uno de los dos valores ( Ciudad_desde_nodo01 o Ciudad_desde_nodo03 ) estará
presente, y será el mismo en los tres nodos. Este es el determinismo de Galera: el conflicto se
resuelve de forma consistente globalmente.
Restaurar el valor original:
Bash
sudo mariadb lab_bdd -e "UPDATE clientes SET ciudad = 'Monterrey' WHERE id
= 1;"
E.17 Simular caída y recuperación automática de un nodo (host + VM)
Paso 1: Verificar estado inicial (3 nodos).
Bash
# En cualquier nodo
sudo mariadb -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# → debe devolver 3
Paso 2: Simular caída abrupta de bdd-nodo02 .
PowerShell
# Desde el host Windows (simula fallo de hardware, sin apagado limpio)
VBoxManage controlvm "bdd-nodo02" poweroff
Paso 3: Verificar que el clúster sigue operando con 2 nodos.
26

Bash
# En bdd-nodo01 o bdd-nodo03
sudo mariadb -e "SHOW STATUS LIKE 'wsrep_cluster_size';" # → 2
sudo mariadb -e "SHOW STATUS LIKE 'wsrep_cluster_status';" # → Primary
Paso 4: Insertar datos mientras nodo02 está caído.
Bash
# En bdd-nodo01
sudo mariadb lab_bdd -e "
INSERT INTO clientes (nombre, apellido, email, telefono, region, ciudad)
VALUES ('Prueba', 'Recuperacion', 'prueba.recovery@lab.test',
'5500000023', 'este', 'Veracruz');
SELECT 'Registro insertado con nodo02 caido' AS mensaje,
LAST_INSERT_ID() AS id_asignado;
"
Paso 5: Reiniciar bdd-nodo02 y observar la rejointura automática.
PowerShell
# Desde el host
VBoxManage startvm "bdd-nodo02" --type headless
Esperar 30–60 segundos. Monitorear los logs de nodo02:
Bash
# En bdd-nodo02 (cuando SSH esté disponible)
sudo journalctl -u mariadb -f --no-pager | grep -E
"WSREP|IST|SST|Synced|joining"
# Buscar: "WSREP: Synchronized with group, ready for connections"
Paso 6: Verificar que nodo02 recuperó el registro insertado durante la caída.
27

Bash
# En bdd-nodo02
sudo mariadb lab_bdd -e "
SELECT id, nombre, apellido, email, ciudad
FROM clientes WHERE email = 'prueba.recovery@lab.test';
"
sudo mariadb -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# → debe volver a 3
E.18 Apagar los tres nodos ordenadamente y tomar snapshots (host + VM)
El orden de apagado de un clúster Galera importa: apagar los joiners primero y el bootstrapper
(o el nodo con mayor seqno ) al final. El último en apagarse limpiamente tendrá
safe_to_bootstrap: 1 en su archivo grastate.dat .
Bash
# En bdd-nodo03 (apagar primero)
sudo systemctl stop mariadb && sudo poweroff
# En bdd-nodo02 (apagar segundo)
sudo systemctl stop mariadb && sudo poweroff
# En bdd-nodo01 (apagar ÚLTIMO)
sudo systemctl stop mariadb && sudo poweroff
Confirmar desde el host:
PowerShell
VBoxManage list runningvms
# La salida debe estar vacía
Tomar los snapshots de cierre de fase:
28

PowerShell
VBoxManage snapshot "bdd-nodo01" take "fase11-completa" `
--description "Galera Cluster activo (nodo01 bootstrapper). lab_bdd con 22
clientes. wsrep_cluster_size=3, status=Primary. Binary log conservado para
async downstream."
VBoxManage snapshot "bdd-nodo02" take "fase11-completa" `
--description "Galera Cluster miembro. Configuracion esclavo Fase10
eliminada. Sincronizado via SST. lab_bdd verificada."
VBoxManage snapshot "bdd-nodo03" take "fase11-completa" `
--description "Tercer miembro Galera. Creado como clon de nodo01@fase09-
completa. IP .103, server_id=3. lab_bdd sincronizada por Galera."
Confirmar los snapshots:
PowerShell
VBoxManage snapshot "bdd-nodo01" list
VBoxManage snapshot "bdd-nodo02" list
VBoxManage snapshot "bdd-nodo03" list
bdd-nodo01 y bdd-nodo02 deben mostrar los snapshots fase05-completa a fase11-
completa . bdd-nodo03 debe mostrar únicamente fase11-completa (su primer snapshot).
F. Verificación de funcionamiento
Esta fase se considera completa cuando se cumplen todos los puntos siguientes con el
clúster activo:
 Los tres nodos responden a ssh bddadmin@192.168.56.10X desde el host Windows sin
errores
 SHOW STATUS LIKE 'wsrep_cluster_size'; devuelve  en los tres nodos
 SHOW STATUS LIKE 'wsrep_cluster_status'; devuelve Primary en los tres nodos
 SHOW STATUS WHERE Variable_name = 'wsrep_local_state_comment'; devuelve Synced
en los tres nodos
 SELECT * FROM information_schema.WSREP_MEMBERSHIP; muestra exactamente  filas
con los nombres bdd-nodo01  bdd-nodo02  bdd-nodo03 y sus IPs correctas
 El conteo de registros en lab_bdd es idéntico en los tres nodos ≥ clientes (
originales + los insertados en las pruebas)  productos  pedidos  detalles
 Un INSERT ejecutado en nodo es inmediatamente visible en nodo y nodo sin
ningún comando adicional
29

 Un INSERT ejecutado en nodo es inmediatamente visible en nodo y nodo
 El experimento de conflicto (E) produjo exactamente un error en una de las dos
sesiones y el valor de la columna ciudad del cliente id = 1 es el mismo en los tres
nodos (resultado determinista)
 SHOW VARIABLES LIKE 'auto_increment_increment'; devuelve  en los tres nodos
 El experimento de caída de nodo (E) mostró wsrep_cluster_size = 2 durante la
caída wsrep_cluster_status = Primary con  nodos el registro
prueba.recovery@lab.test aparece en nodo tras su reinicio wsrep_cluster_size =
3 tras la recuperación
 SHOW VARIABLES LIKE 'wsrep_on'; devuelve ON en los tres nodos
 Los snapshots fase11-completa existen en los tres nodos
 El estudiante puede explicar de memoria la diferencia entre SST e IST y cuándo Galera
elige cada mecanismo
 El estudiante puede explicar qué es el Componente Primario y qué ocurre con un nodo que
pierde quórum
30

G. Problemas comunes y soluciones
| Problema         | Causa probable | Solución        |       |
| ---------------- | -------------- | --------------- | ----- |
| galera_new_clu   | MariaDB sigue  | Ejecutar        | sudo  |
| ster  falla con  | activo         | systemctl stop  |       |
| ERROR: MySQL     |                | mariadb         |  y    |
| is running,      |                | luego  sudo     |       |
please stop it  galera_new_clu
first ster
| El nodo joiner  | Falla de         | Verificar         | ping   |
| --------------- | ---------------- | ----------------- | ------ |
| permanece en    | conectividad en  | entre VMs si     |        |
| wsrep_local_st  | el puerto    | ufw está activo  |        |
| ate_comment =   | entre los nodos  | ejecutar E    |        |
| Joining  sin    |                  | probar con        | nc -   |
avanzar zv
192.168.56.101
4567  desde el
joiner
| El SST tarda  | Con  rsync       |  el  Es normal  |     |
| ------------- | ---------------- | ----------------- | --- |
| más de       | SST es una       | esperar Para     |     |
| minutos       | copia completa  | datos             |     |
|               | con mucha        | crecientes       |     |
|               | actividad en el  | cambiar a         |     |
donor puede ser  wsrep_sst_meth
lento od =
mariabackup
(requiere
instalar
mariadb-
backup )
|     | Galera detecta  | Verificar que los  |     |
| --- | --------------- | ------------------ | --- |
galera_new_clu
|  muestra  | datos de un  | otros nodos  |     |
| --------- | ------------ | ------------ | --- |
ster
|     | clúster anterior  | están  |     |
| --- | ----------------- | ------ | --- |
WSREP: It may
|     | y teme un  | completamente  |     |
| --- | ---------- | -------------- | --- |
not be safe to
|     | split-brain | detenidos  |     |
| --- | ----------- | ----------- | --- |
bootstrap...
editar
/var/lib/mysql
/grastate.dat
en nodo y
cambiar
safe_to_bootst
rap: 0  a
safe_to_bootst
rap: 1  luego
reintentar
31

| MariaDB no       | Error de sintaxis  | Revisar el error  |     |
| ---------------- | ------------------ | ----------------- | --- |
| arranca después  | en el archivo o    | con  sudo         |     |
| de agregar       | conflicto de       |                   |     |
| 61-              |                    | journalctl -u     |     |
parámetros
| galera.cnf |     | mariadb -n 30  |     |
| ---------- | --- | -------------- | --- |
entre archivos
|     |     | --no-pager |    |
| --- | --- | ---------- | --- |
buscar  unknown
|     |     | variable |  o  |
| --- | --- | -------- | --- |
conflicts
with  para
identificar el
parámetro
problemático
| wsrep_cluster_   | Los nodos no se  | Verificar que  |     |
| ---------------- | ---------------- | -------------- | --- |
| size  sigue en   | alcanzan en el   | wsrep_node_add |     |
|  después de     | puerto wsrep     | ress  en       | 61- |
| unir el segundo  |  aunque      | galera.cnf     |     |
| nodo             | SSH () sí      | coincide       |     |
|                  | funcione         | exactamente    |     |
con la IP de la
interfaz Host-
Only revisar
ufw
| El experimento   | El SLEEP fue    | Aumentar el       |     |
| ---------------- | --------------- | ----------------- | --- |
| de conflicto no  | insuficiente   | SLEEP a         |     |
| genera error    | nodo          | segundos         |     |
| ambas            | confirmó antes  | asegurarse de     |     |
| transacciones    | de que nodo   | que la sesión en  |     |
| confirman        | empezara        | nodo inició el  |     |
UPDATE ANTES
de que nodo
llamara al
COMMIT
| wsrep_cluster_ | El nodo perdió   | Si los otros dos  |     |
| -------------- | ---------------- | ----------------- | --- |
|                | contacto con la  | nodos están       |     |
status = non-
|                 | mayoría del  |                  |  el  |
| --------------- | ------------ | ---------------- | ----- |
| Primary  en un  |              | Primary          |       |
|                 | clúster      | nodo aislado se  |       |
nodo tras
reconectará
reinicio
automáticament
e al recuperar la
red
| Tras una caída    | Galera no sabe   | Revisar  |     |
| ----------------- | ---------------- | -------- | --- |
| total (todos los  | cuál nodo tiene  |          |     |
/var/lib/mysql
| nodos apagados  | el estado más  |     |     |
| --------------- | -------------- | --- | --- |
/grastate.dat
| sin orden)  | reciente | en cada nodo el  |     |
| ------------ | -------- | ----------------- | --- |
| ningún nodo  |          | que tenga         |     |
| arranca el   |          | seqno  más alto   |     |
| clúster      |          | Y                 |     |
32

safe_to_bootst
rap: 1  debe
ejecutar
galera_new_clu
ster  los
demás luego
con  systemctl
start mariadb
| El clon de       | VirtualBox   | En nodo:  |     |
| ---------------- | ------------ | ----------- | --- |
| nodo tiene el  | regenera el  |             |     |
sudo rm
| mismo  | UUID de VM  |     |     |
| ------ | ----------- | --- | --- |
/etc/machine-
pero no el ID del
| /etc/machine- |          | id && sudo  |     |
| ------------- | -------- | ----------- | --- |
|  que nodo   | sistema  |             |     |
| id            |          | systemd-    |     |
operativo
machine-id-
setup  y
reiniciar
| auto_increment | wsrep_auto_inc  | Verificar con   |     |
| -------------- | --------------- | --------------- | --- |
|                |                 | SHOW VARIABLES  |     |
| _increment     | rement_control  |                 |     |
| sigue en      |  no está        | LIKE            |     |
= ON
| después de  | en  | 'wsrep_auto_in |     |
| ----------- | --- | -------------- | --- |
61-
| activar Galera |  o  | crement_contro |     |
| -------------- | --- | -------------- | --- |
galera.cnf
|     | el archivo no se  |  si  |     |
| --- | ----------------- | ----- | --- |
l';
|     | cargó | devuelve  |    |
| --- | ----- | --------- | --- |
OFF
agregar el
parámetro al
archivo y
reiniciar
MariaDB
H. Checklist de validación
bdd-nodo03  existe en VirtualBox con IP  192.168.56.103 , hostname  bdd-nodo03  y
acceso SSH desde el host.
bdd-nodo03  tiene  server_id = 3  confirmado con  SELECT @@server_id; .
El paquete  galera-4  está instalado y  /usr/lib/galera/libgalera_smm.so  existe en los
tres nodos.
 existe en los tres nodos con
/etc/mysql/mariadb.conf.d/61-galera.cnf
| wsrep_node_address |  y  wsrep_node_name |  únicos para cada nodo. |     |
| ------------------ | ------------------- | ----------------------- | --- |
La configuración de esclavo de la Fase 10 fue eliminada de  bdd-nodo02 :  RESET SLAVE
|  ejecutado y  |  eliminado del archivo de configuración. |     |     |
| ------------- | ---------------------------------------- | --- | --- |
| ALL           | read_only                                |     |     |
El bootstrap se completó en   sin errores y el servicio   está activo.
bdd-nodo01 mariadb
33

bdd-nodo02 y bdd-nodo03 se unieron al clúster; sus logs muestran Synchronized with
group .
SHOW STATUS LIKE 'wsrep_cluster_size'; devuelve 3 en los tres nodos.
SHOW STATUS LIKE 'wsrep_cluster_status'; devuelve Primary en los tres nodos.
wsrep_local_state_comment = Synced en los tres nodos.
information_schema.WSREP_MEMBERSHIP muestra 3 filas con nodos, IPs y nombres
correctos.
El conteo de registros en lab_bdd es idéntico en los tres nodos.
Se demostró inserción en nodo01 visible inmediatamente en nodo02 y nodo03.
Se demostró inserción en nodo03 visible inmediatamente en nodo01 y nodo02.
El experimento de conflicto generó exactamente un error en una de las dos sesiones.
El valor del cliente id = 1 es idéntico en los tres nodos tras el experimento de conflicto.
El experimento de caída de nodo02 mostró wsrep_cluster_size = 2 durante la caída y
3 tras la recuperación.
El registro prueba.recovery@lab.test aparece en nodo02 tras su reinicio, sin
intervención manual.
SHOW VARIABLES LIKE 'auto_increment_increment'; devuelve 3 en los tres nodos.
Los snapshots fase11-completa existen en los tres nodos.
Puedo explicar la diferencia entre SST e IST y cuándo Galera elige cada uno.
Puedo explicar qué es el Componente Primario y qué ocurre cuando un nodo
pierde quórum.
Preguntas teóricas para estudiantes
 La replicación de Galera se denomina “síncrona por certificación” pero no usa commit de
dos fases clásico (PC) ni locks distribuidos durante la ejecución de la transacción Explica
en detalle ¿qué información contiene exactamente un write-set? ¿qué condición verifica
cada nodo durante la certificación? y ¿por qué este mecanismo puede garantizar
consistencia global sin necesitar que los nodos se comuniquen durante la ejecución de la
transacción (solo al momento del COMMIT )?
 Un clúster de  nodos tolera la caída de  nodo simultáneo Si el sistema de producción
necesitara tolerar  nodos caídos simultáneamente ¿cuántos nodos totales se requerirían
y por qué? Generaliza la fórmula para una tolerancia a f fallos y explica por qué Galera (y
cualquier sistema basado en quórum) opera correctamente con número impar de nodos
pero tiene problemas estructurales con número par
34

 En el experimento de conflicto (sección E) la transacción perdedora recibió un error de
tipo deadlock Desde el punto de vista del código de una aplicación que usa este clúster
¿qué estrategia de manejo de errores es necesaria para que las escrituras sean robustas
ante conflictos de certificación? ¿Es suficiente capturar el error y reintentar sin más? ¿Qué
cuidados especiales hay que tener en el reintento para no violar la lógica de negocio?
 wsrep_auto_increment_control = ON hace que Galera ajuste
auto_increment_increment y auto_increment_offset según el número de nodos ¿Qué
ocurre internamente cuando un cuarto nodo se une al clúster en caliente (sin reiniciar los
otros nodos)?: ¿cómo cambian estos valores en todos los nodos? ¿qué sucede con las
filas ya insertadas que tienen IDs generados con el patrón de  nodos? ¿produce esto
algún hueco en la secuencia y es eso un problema?
 Dado el diseño completo del laboratorio (Galera en nodo– fragmentación en nodo–
 coordinador Spider en nodo) identifica dos escenarios de partición de red
distintos y explica para cada uno qué dilema CAP presenta ¿qué parte del sistema elegirá
Consistencia (dejando de aceptar escrituras) y qué parte elegirá Disponibilidad (aceptando
escrituras con riesgo de inconsistencia)?
Ejercicios prácticos
 Comparación de latencia asíncrona (Fase ) vs síncrona (Galera)
Usando los snapshots fase10-completa de nodo y nodo (desde una sesión
VirtualBox paralela sin afectar el clúster activo) diseñar un experimento que inserte 
filas en el maestro de la Fase  y mida el tiempo promedio entre el COMMIT en el maestro
y la disponibilidad del dato en el esclavo (via SELECT COUNT(*) iterativo) Realizar la
misma medición en el clúster Galera activo Comparar los resultados y explicar qué
significa la diferencia para una aplicación que necesita leer inmediatamente después de
escribir
 Script de monitoreo de salud del clúster Galera
Escribir un script Bash ( /opt/lab_bdd_backups/galera_health.sh ) que se conecte a
MariaDB y genere un reporte con tamaño del clúster estado de cada nodo
( wsrep_local_state_comment ) bytes replicados acumulados transacciones en cola
( wsrep_local_send_queue ) y un semáforo basado en las condiciones verde =  nodos
Primary Synced amarillo =  nodos Primary rojo = menos de  nodos o estado non-
Primary El script debe poder ejecutarse desde cualquier nodo e indicar desde cuál nodo
reporta
 Análisis del archivo grastate.dat antes y después de un apagado ordenado
Antes de apagar el clúster (con sudo systemctl stop mariadb ) registrar el contenido de
/var/lib/mysql/grastate.dat en los tres nodos Luego apagar en el orden correcto
(nodo nodo nodo) y volver a leer el archivo en cada nodo Comparar los valores
35

de uuid  seqno y safe_to_bootstrap antes y después del apagado Documentar qué
nodo tiene safe_to_bootstrap: 1 y explicar el procedimiento correcto para recuperar el
clúster tras una caída total inesperada (todos los nodos apagados de golpe)
Reto adicional para alumnos avanzados
Configurar un esclavo asíncrono tradicional apuntando a bdd-nodo01 (miembro del clúster
Galera) desde un cuarto nodo hipotético creado como clon limpio. Las escrituras al clúster se
harían con las garantías síncronas de Galera, y la réplica asíncrona serviría para offloading de
respaldos. El reto requiere: (a) investigar y documentar el problema de los GTIDs de Galera
( wsrep_gtid_mode ) vs los GTIDs de MariaDB y cómo coexisten; (b) configurar nodo01 para
emitir binary log con una configuración compatible; © verificar que una escritura en cualquier
nodo del clúster llega eventualmente al esclavo async; y (d) elaborar un diagrama de flujo
completo de una transacción desde el cliente hasta el esclavo async, indicando en qué puntos
la propagación es síncrona y en cuáles es asíncrona, y qué datos podría perder el esclavo
async en caso de fallo de nodo01 que no perdería ningún miembro Galera.
36

Criterios de evaluación para el profesor
| Criterio | Peso | Indicador de  |     |
| -------- | ---- | ------------- | --- |
logro
| Creación y     | % | El nodo existe  |     |
| -------------- | --- | --------------- | --- |
| configuración  |     | con IP  .103    |    |
| de  bdd-nodo03 |     | hostname        |     |
correcto
|     |     | server_id = 3 |     |
| --- | --- | ------------- | --- |
y  61-
|     |     | galera.cnf |     |
| --- | --- | ---------- | --- |
con parámetros
únicos clon
tomado de
fase09-
completa
| Configuración  | % | 61-galera.cnf   |     |
| -------------- | --- | --------------- | --- |
| Galera en los  |     | existe en los   |     |
| tres nodos     |     | tres nodos sin  |     |
errores de
sintaxis
MariaDB arranca
con Galera
habilitado
limpieza de
esclavo de Fase
 realizada en
nodo
| Estado del  | % |     |     |
| ----------- | --- | --- | --- |
wsrep_cluster_
clúster
|     |     | size = 3 |    |
| --- | --- | -------- | --- |
verificado
wsrep_cluster_
status =
|     |     | Primary |  y  |
| --- | --- | ------- | --- |
wsrep_local_st
ate_comment =
Synced  en los
tres nodos
simultáneament
e
WSREP_MEMBERSH
IP  muestra los
tres nodos
| Demostración     | % | Se demuestra       |     |
| ---------------- | --- | ------------------ | --- |
| multi-maestro y  |     | escritura exitosa  |     |
| conflictos       |     | desde nodo       |     |
visible en
37

nodo y
desde nodo
visible en
nodo el
experimento de
conflicto
produce
exactamente un
rollback con
resultado
idéntico en los
tres nodos
Caída y % wsrep_cluster_
recuperación size = 2
de nodo durante la caída
= 3 tras la
recuperación el
registro
insertado
durante la caída
aparece en
nodo sin
intervención
manual
Comprensión % Las respuestas
conceptual distinguen
(preguntas correctamente
teóricas) la certificación
Galera del PC
clásico calculan
nodos
necesarios para
tolerancia a
fallos y discuten
la estrategia de
reintento con
vocabulario
técnico
apropiado
Preparación para la siguiente fase
La Fase 12: Particionamiento (técnica de organización interna de datos dentro de un nodo,
puente conceptual hacia la fragmentación horizontal de la Fase 13) requerirá:
• El clúster Galera de tres nodos en estado fase11-completa (esta fase)
38

• El esquema lab_bdd con datos de prueba intactos y consistentes en los tres nodos
• Acceso SSH y DBeaver funcionando hacia los tres nodos (nodo se agrega ahora como
cuarta conexión con túnel SSH siguiendo el mismo procedimiento de la Fase )
• Comprensión clara de la diferencia entre particionamiento (dividir filas dentro de un
mismo nodo usando la directiva PARTITION BY de MariaDB sin mover datos entre
servidores) y fragmentación (distribuir datos entre nodos distintos que se implementa en
la Fase ) Esa distinción es el hilo conductor de la Fase 
Cualquier operación DDL ( CREATE TABLE , ALTER TABLE ... PARTITION BY ) que se ejecute en
un nodo del clúster Galera se propagará automáticamente a los otros dos, lo que permite
verificar que el DDL de particionamiento se replica correctamente — una verificación adicional
de que el clúster sigue funcionando bien después de esta fase.
39