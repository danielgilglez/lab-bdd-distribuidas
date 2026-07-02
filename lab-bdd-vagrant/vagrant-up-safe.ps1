param(
    [Parameter(Mandatory)]
    [string]$NodeName,
    [switch]$ProvisionOnly,
    [switch]$DestroyFirst
)

$ErrorActionPreference = "Continue"

# Obtener ruta del proyecto
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ProjectRoot

# Log con timestamp
function Write-Log { param([string]$Msg) Write-Host "[$(Get-Date -Format HH:mm:ss)] $Msg" }

# Esperar a que SSH responda en el puerto de Vagrant
function Wait-For-SSH {
    param([int]$Port, [int]$TimeoutSeconds = 600)
    $start = Get-Date
    while (1) {
        try {
            $sock = New-Object System.Net.Sockets.TcpClient
            $conn = $sock.BeginConnect("127.0.0.1", $Port, $null, $null)
            if ($conn.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(5), $false)) {
                $sock.EndConnect($conn)
                $sock.Close()
                Write-Log "SSH disponible en puerto $Port"
                return $true
            }
        } catch {
            # ignorar errores de conexión
        }
        $elapsed = [math]::Round(((Get-Date) - $start).TotalSeconds)
        if ($elapsed -ge $TimeoutSeconds) {
            Write-Log "ERROR: Timeout esperando SSH ($TimeoutSeconds s)"
            return $false
        }
        Write-Log "Esperando SSH... ($elapsed s)"
        Start-Sleep -Seconds 10
    }
}

# Obtener nombre exacto de la VM en VirtualBox
$VboxName = "lab-bdd-vagrant_${NodeName,,}"
$VmExists = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list vms | Select-String -Pattern "^`"$VboxName`""
$VmRunning = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list runningvms | Select-String -Pattern "^`"$VboxName`""

if ($DestroyFirst -and $VmExists) {
    Write-Log "Destruyendo VM existente $VboxName..."
    vagrant destroy -f $NodeName 2>&1 | Out-Null
    if ($LASTEXITCODE) { & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" unregistervm "$VboxName" --delete 2>&1 | Out-Null }
    $VmExists = $null
}

if ($ProvisionOnly) {
    # Solo reprovisionar (la VM ya debe estar corriendo)
    Write-Log "Reprovisionando $NodeName..."
    vagrant provision $NodeName 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Log "ERROR: vagrant provision falló"; exit 1 }
    Write-Log "OK: $NodeName provisionado"
    exit 0
}

if (-not $VmExists) {
    # La VM no existe -> usar vagrant up normalmente (con GUI=false el boot es rápido)
    Write-Log "Creando VM $NodeName desde cero..."
    vagrant up $NodeName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "vagrant up falló, intentando método alternativo (headless + provision)..."
        # Último recurso: esperar que la VM arranque y luego forzar provision
        Start-Sleep -Seconds 120
        vagrant provision $NodeName 2>&1
        if ($LASTEXITCODE -ne 0) { Write-Log "ERROR: No se pudo provisionar $NodeName"; exit 1 }
    }
    Write-Log "OK: $NodeName creado y provisionado"
    exit 0
}

# La VM existe
if ($VmRunning) {
    Write-Log "VM $VboxName ya está corriendo"
} else {
    Write-Log "Iniciando VM $VboxName (headless)..."
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "$VboxName" --type headless 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Log "ERROR: No se pudo iniciar VM"; exit 1 }
}

# Obtener puerto SSH (mirar forwarding de Vagrant)
$VagrantSshConfig = vagrant ssh-config $NodeName 2>&1 | Out-String
$SshPort = 22
if ($VagrantSshConfig -match "Port (\d+)") { $SshPort = [int]$Matches[1] }
Write-Log "Puerto SSH: $SshPort"

# Esperar SSH
if (-not (Wait-For-SSH -Port $SshPort)) {
    Write-Log "ERROR: SSH no disponible después de espera prolongada"
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm "$VboxName" savestate 2>&1 | Out-Null
    exit 1
}

# Forzar que Vagrant registre la VM como "running"
Write-Log "Ejecutando vagrant provision $NodeName..."
vagrant provision $NodeName 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Log "ERROR: vagrant provision falló"
    exit 1
}

Write-Log "OK: $NodeName listo"
exit 0
