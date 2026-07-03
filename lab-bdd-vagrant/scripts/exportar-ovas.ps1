<#
.SYNOPSIS
  Exporta las VMs del laboratorio BDD a archivos .OVA para usar en
  VirtualBox sin Vagrant.

.DESCRIPTION
  Detecta VBoxManage, localiza las VMs bdd-nodo*, elimina la carpeta
  compartida de Vagrant, y exporta cada VM como OVA (OVF 1.0).

.PARAMETER VMs
  Lista de VMs a exportar. Por defecto: todas las bdd-nodo* registradas.
  Ej: @("bdd-nodo01","bdd-nodo03")

.PARAMETER OutputDir
  Directorio donde guardar los .OVA. Por defecto: ./exports/

.PARAMETER SkipCleanup
  Omite la limpieza interna de las VMs (apt, logs) y el apagado.

.EXAMPLE
  .\scripts\exportar-ovas.ps1
  Exporta todas las VMs bdd-nodo* a ./exports/

.EXAMPLE
  .\scripts\exportar-ovas.ps1 -VMs @("bdd-nodo01","bdd-nodo02") -OutputDir "D:\backup"
  Exporta solo nodo01 y nodo02 a D:\backup\

.EXAMPLE
  .\scripts\exportar-ovas.ps1 -SkipCleanup
  Exporta sin detener VMs ni limpiar (asume que ya estan apagadas)
#>

param(
    [string[]]$VMs,
    [string]$OutputDir = "",
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

# 1. Detectar VBoxManage
function Find-VBoxManage {
    $paths = @(
        "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
        "C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe",
        (Get-Command "VBoxManage.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    throw "VBoxManage.exe no encontrado. VirtualBox esta instalado?"
}

$VBoxManage = Find-VBoxManage
Write-Output "[INFO] VBoxManage: $VBoxManage"
Write-Output ""

# 2. Detectar VMs disponibles
$allVMs = @(& $VBoxManage list vms | ForEach-Object {
    if ($_ -match '^"(.+)"\s+\{') { $matches[1] }
})

$bddVMs = $allVMs | Where-Object { $_ -like "bdd-nodo*" } | Sort-Object

if ($bddVMs.Count -eq 0) {
    Write-Output "[ERROR] No se encontraron VMs bdd-nodo* en VirtualBox."
    Write-Output ("  VMs registradas: " + ($allVMs -join ', '))
    exit 1
}

if ($VMs.Count -eq 0) {
    $VMs = $bddVMs
} else {
    foreach ($vm in $VMs) {
        if ($vm -notin $bddVMs) {
            Write-Output ("[ERROR] La VM '" + $vm + "' no esta registrada en VirtualBox.")
            Write-Output ("  VMs disponibles: " + ($bddVMs -join ', '))
            exit 1
        }
    }
}

if (-not $OutputDir) {
    $scriptDir = Split-Path -Parent $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = Get-Location }
    $OutputDir = Join-Path $scriptDir "exports"
}

Write-Output ("[INFO] VMs a exportar: " + ($VMs -join ', '))
Write-Output ("[INFO] Directorio destino: " + $OutputDir)
Write-Output ""

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# 3. Detectar Vagrant (opcional)
$Vagrant = Get-Command "vagrant" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $Vagrant) {
    Write-Output "[AVISO] Vagrant no encontrado en PATH. Solo se usara VBoxManage."
    Write-Output "  Si las VMs estan corriendo, debes apagarlas manualmente."
    Write-Output ""
}

# 4. Limpiar y apagar VMs
if (-not $SkipCleanup) {
    Write-Output "=============================================="
    Write-Output "  LIMPIEZA Y APAGADO DE VMs"
    Write-Output "=============================================="

    foreach ($vm in $VMs) {
        Write-Output ("[" + $vm + "] Limpiando...")

        $state = & $VBoxManage showvminfo "$vm" --machinereadable 2>&1 |
            Select-String "^VMState=" |
            ForEach-Object { $_ -replace '^VMState="([^"]+)"','$1' }

        if ($state -eq "running" -or $state -eq "paused") {
            if ($Vagrant) {
                Write-Output "  Apagando con vagrant halt..."
                & $Vagrant halt $vm 2>&1 | Out-Null
            } else {
                Write-Output "  Apagando con ACPI..."
                & $VBoxManage controlvm "$vm" acpipowerbutton 2>&1 | Out-Null
                Start-Sleep -Seconds 10
                $state2 = & $VBoxManage showvminfo "$vm" --machinereadable 2>&1 |
                    Select-String "^VMState=" |
                    ForEach-Object { $_ -replace '^VMState="([^"]+)"','$1' }
                if ($state2 -eq "running") {
                    & $VBoxManage controlvm "$vm" poweroff 2>&1 | Out-Null
                }
            }

            $timeout = 30
            while ($timeout -gt 0) {
                $st = & $VBoxManage showvminfo "$vm" --machinereadable 2>&1 |
                    Select-String "^VMState=" |
                    ForEach-Object { $_ -replace '^VMState="([^"]+)"','$1' }
                if ($st -eq "poweroff") { break }
                Start-Sleep -Seconds 2
                $timeout -= 2
            }

            if ($timeout -le 0) {
                Write-Output "  No se pudo apagar del todo, forzando..."
                & $VBoxManage controlvm "$vm" poweroff 2>&1 | Out-Null
                Start-Sleep -Seconds 3
            }
        } else {
            Write-Output ("  Ya esta apagada (state: " + $state + ")")
        }

        if ($Vagrant) {
            Write-Output "  Limpiando apt cache y logs..."
            & $Vagrant ssh $vm -c "sudo bash -c '
                apt-get clean -qq 2>/dev/null
                journalctl --vacuum-time=1s 2>/dev/null
                rm -rf /var/log/*.gz /var/log/*.old 2>/dev/null
                > /var/log/mysql/mariadb.err 2>/dev/null || true
                rm -rf /tmp/* 2>/dev/null || true
            '" 2>&1 | Out-Null
        }

        Write-Output "  OK"
    }
    Write-Output ""
}

# 5. Eliminar shared folder de Vagrant
Write-Output "=============================================="
Write-Output "  ELIMINAR CARPETA COMPARTIDA VAGRANT"
Write-Output "=============================================="

foreach ($vm in $VMs) {
    Write-Output ("[" + $vm + "] Eliminando shared folder 'vagrant'...")
    & $VBoxManage sharedfolder remove "$vm" --name "vagrant" 2>&1 | Out-Null

    $sfCheck = & $VBoxManage showvminfo "$vm" 2>&1 | Select-String -SimpleMatch "vagrant"
    if ($sfCheck) {
        Write-Output "  No se pudo eliminar. Continuando..."
    } else {
        Write-Output "  Eliminado"
    }
}
Write-Output ""

# 6. Exportar a OVA
Write-Output "=============================================="
Write-Output "  EXPORTANDO VMs A OVA"
Write-Output "=============================================="

$results = @{}

foreach ($vm in $VMs) {
    $ovaFile = Join-Path $OutputDir "$vm.ova"
    Write-Output ("[" + $vm + "] Exportando -> " + $ovaFile + " ...")
    Write-Output "  (esto puede tomar varios minutos)"

    try {
        & $VBoxManage export "$vm" -o "$ovaFile" --ovf10 --options=manifest 2>&1 |
            ForEach-Object {
                if ($_ -match '(\d+)%') {
                    $pct = [int]$matches[1]
                    if ($pct % 20 -eq 0) { Write-Output ("  ... " + $pct + "%") }
                }
            }

        if (Test-Path $ovaFile) {
            $size = (Get-Item $ovaFile).Length / 1MB
            $results[$vm] = @{ Status = "OK"; SizeMB = [math]::Round($size, 1) }
            Write-Output ("  OK " + $vm + " exportado: " + [math]::Round($size,1) + " MB")
        } else {
            $results[$vm] = @{ Status = "ERROR"; SizeMB = 0 }
            Write-Output ("  FAIL " + $vm + ": archivo no encontrado despues de exportar")
        }
    } catch {
        $results[$vm] = @{ Status = "ERROR"; SizeMB = 0 }
        Write-Output ("  FAIL " + $vm + ": " + $_)
    }
    Write-Output ""
}

# 7. Resumen final
Write-Output "=============================================="
Write-Output "  RESUMEN DE EXPORTACION"
Write-Output "=============================================="

$totalMB = 0
foreach ($vm in $VMs) {
    $r = $results[$vm]
    $statusIcon = if ($r.Status -eq "OK") { "OK" } else { "FAIL" }
    $sizeStr = if ($r.SizeMB -gt 0) { "$($r.SizeMB) MB" } else { "FALLO" }
    Write-Output ("  " + $statusIcon + " " + $vm + " -> " + $sizeStr)
    if ($r.SizeMB -gt 0) { $totalMB += $r.SizeMB }
}

Write-Output ""
Write-Output ("  Total: " + [math]::Round($totalMB,1) + " MB en " + $VMs.Count + " archivo(s)")
Write-Output ("  Destino: " + $OutputDir)
Write-Output ""

if ($SkipCleanup) {
    Write-Output "[NOTA] Se omitio la limpieza (-SkipCleanup)."
    Write-Output "  Las VMs pueden tener logs/cache que ocupen mas espacio."
} else {
    Write-Output "[NOTA] Las VMs quedaron apagadas. Usa vagrant up para reiniciarlas."
}
Write-Output ""
Write-Output "Para importar en VirtualBox sin Vagrant:"
Write-Output "  1. VirtualBox -> Archivo -> Importar servicio virtualizado"
Write-Output "  2. Crear red Host-Only: 192.168.56.1 / 255.255.255.0"
Write-Output "  3. Iniciar VMs (orden: nodo01, nodo02, nodo03, nodo04, nodo05, nodo06)"
Write-Output "  4. SSH: bddadmin / bddadmin"
Write-Output "  5. MariaDB root: LabAdmin_2025!"
