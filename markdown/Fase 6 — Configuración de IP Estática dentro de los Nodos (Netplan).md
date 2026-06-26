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