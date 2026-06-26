$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$env:VAGRANT_HOME = Join-Path $projectRoot ".vagrant-home"
$env:VBOX_USER_HOME = Join-Path $projectRoot ".vbox-home"

if (!(Test-Path $env:VAGRANT_HOME)) { New-Item -ItemType Directory -Path $env:VAGRANT_HOME -Force | Out-Null }
if (!(Test-Path $env:VBOX_USER_HOME)) { New-Item -ItemType Directory -Path $env:VBOX_USER_HOME -Force | Out-Null }

# Force VMs into project folder (opcional, no crítico)
$machineFolder = Join-Path $projectRoot ".vbox-machines"
if (!(Test-Path $machineFolder)) { New-Item -ItemType Directory -Path $machineFolder -Force | Out-Null }
$vboxManage = (Get-Command "VBoxManage" -ErrorAction SilentlyContinue).Source
if ($vboxManage) {
    & $vboxManage setproperty machinefolder "$machineFolder" 2>$null
} else {
    Write-Host "[up.ps1] VBoxManage no encontrado en PATH (las VMs irán a la carpeta por defecto de VirtualBox)"
}

Set-Location $projectRoot

$argsJoined = $args -join " "
Write-Host "[up.ps1] VAGRANT_HOME = $env:VAGRANT_HOME"
Write-Host "[up.ps1] VBOX_USER_HOME = $env:VBOX_USER_HOME"
Write-Host "[up.ps1] Ejecutando: vagrant $argsJoined"
Write-Host ""

vagrant @args
