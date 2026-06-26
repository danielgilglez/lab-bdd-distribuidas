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