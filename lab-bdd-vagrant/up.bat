@echo off
setlocal

set "PROJECT=%~dp0"
set "PROJECT=%PROJECT:~0,-1%"

set "VAGRANT_HOME=%PROJECT%\.vagrant-home"
set "VBOX_USER_HOME=%PROJECT%\.vbox-home"

if not exist "%VAGRANT_HOME%" mkdir "%VAGRANT_HOME%"
if not exist "%VBOX_USER_HOME%" mkdir "%VBOX_USER_HOME%"

VBoxManage setproperty machinefolder "%PROJECT%\.vbox-machines" >nul 2>&1

cd /d "%PROJECT%"

echo [up.bat] VAGRANT_HOME=%VAGRANT_HOME%
echo [up.bat] VBOX_USER_HOME=%VBOX_USER_HOME%
echo [up.bat] Ejecutando: vagrant %*
echo.

vagrant %*
