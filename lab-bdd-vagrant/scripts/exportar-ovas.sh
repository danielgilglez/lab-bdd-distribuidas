#!/bin/bash
# Exporta las VMs del laboratorio BDD a .OVA para VirtualBox solo.
# Uso:  bash scripts/exportar-ovas.sh [--skip-cleanup] [--output-dir DIR] [VM1 VM2 ...]

set -e

# ── Config ──────────────────────────────────────
OUTPUT_DIR="${PWD}/exports"
SKIP_CLEANUP=false
SELECTED_VMS=()

# ── Argumentos ──────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-cleanup) SKIP_CLEANUP=true; shift ;;
        --output-dir)   OUTPUT_DIR="$2";  shift 2 ;;
        *)              SELECTED_VMS+=("$1"); shift ;;
    esac
done

# ── Detectar VBoxManage ─────────────────────────
VBOXMANAGE=""
for p in /usr/bin/VBoxManage /usr/lib/virtualbox/VBoxManage \
         "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" \
         "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"; do
    if [ -x "$p" ] || [ -f "$p" ]; then
        VBOXMANAGE="$p"
        break
    fi
done

if [ -z "$VBOXMANAGE" ]; then
    VBOXMANAGE=$(command -v VBoxManage 2>/dev/null || true)
fi

if [ -z "$VBOXMANAGE" ]; then
    echo "[ERROR] VBoxManage no encontrado. Instala VirtualBox."
    exit 1
fi
echo "[INFO] VBoxManage: $VBOXMANAGE"
echo ""

# ── Detectar VMs ────────────────────────────────
ALL_VMS=$("$VBOXMANAGE" list vms 2>/dev/null | grep -oP '"\K[^"]+' || true)
BDD_VMS=$(echo "$ALL_VMS" | grep "bdd-nodo" | sort || true)

if [ -z "$BDD_VMS" ]; then
    echo "[ERROR] No se encontraron VMs bdd-nodo*."
    echo "  VMs registradas: $(echo "$ALL_VMS" | tr '\n' ' ')"
    exit 1
fi

if [ ${#SELECTED_VMS[@]} -eq 0 ]; then
    IFS=$'\n' read -d '' -r -a SELECTED_VMS <<< "$BDD_VMS" || true
fi

echo "[INFO] VMs a exportar: ${SELECTED_VMS[*]}"
echo "[INFO] Directorio destino: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo ""

# ── Detectar Vagrant (opcional) ─────────────────
VAGRANT=$(command -v vagrant 2>/dev/null || true)

# ── Limpiar y apagar VMs ────────────────────────
if [ "$SKIP_CLEANUP" = false ]; then
    echo "=============================================="
    echo "  LIMPIEZA Y APAGADO"
    echo "=============================================="

    for vm in "${SELECTED_VMS[@]}"; do
        echo "[$vm] Limpiando..."

        # Estado actual
        state=$("$VBOXMANAGE" showvminfo "$vm" --machinereadable 2>/dev/null |
                grep "^VMState=" | sed 's/VMState="//;s/"//' || echo "unknown")

        if [ "$state" = "running" ] || [ "$state" = "paused" ]; then
            if [ -n "$VAGRANT" ]; then
                echo "  → Apagando con vagrant halt..."
                vagrant halt "$vm" 2>/dev/null || true
            else
                echo "  → Apagando con ACPI..."
                "$VBOXMANAGE" controlvm "$vm" acpipowerbutton 2>/dev/null || true
                sleep 10
                state2=$("$VBOXMANAGE" showvminfo "$vm" --machinereadable 2>/dev/null |
                         grep "^VMState=" | sed 's/VMState="//;s/"//' || echo "unknown")
                if [ "$state2" = "running" ]; then
                    "$VBOXMANAGE" controlvm "$vm" poweroff 2>/dev/null || true
                fi
            fi

            # Esperar apagado
            for i in $(seq 1 15); do
                st=$("$VBOXMANAGE" showvminfo "$vm" --machinereadable 2>/dev/null |
                     grep "^VMState=" | sed 's/VMState="//;s/"//' || echo "unknown")
                [ "$st" = "poweroff" ] && break
                sleep 2
            done
        else
            echo "  → Ya apagada (state: $state)"
        fi

        # Limpieza interna via Vagrant
        if [ -n "$VAGRANT" ]; then
            echo "  → Limpiando apt cache y logs..."
            vagrant ssh "$vm" -c "sudo bash -c '
                apt-get clean -qq 2>/dev/null
                journalctl --vacuum-time=1s 2>/dev/null
                rm -rf /var/log/*.gz /var/log/*.old 2>/dev/null
                > /var/log/mysql/mariadb.err 2>/dev/null || true
                rm -rf /tmp/* 2>/dev/null || true
            '" 2>/dev/null || true
        fi

        echo "  ✓ OK"
    done
    echo ""
fi

# ── Eliminar shared folder vagrant ──────────────
echo "=============================================="
echo "  ELIMINAR CARPETA COMPARTIDA VAGRANT"
echo "=============================================="

for vm in "${SELECTED_VMS[@]}"; do
    echo "[$vm] Eliminando shared folder 'vagrant'..."
    "$VBOXMANAGE" sharedfolder remove "$vm" --name "vagrant" 2>/dev/null || true
    echo "  ✓"
done
echo ""

# ── Exportar a OVA ──────────────────────────────
echo "=============================================="
echo "  EXPORTANDO A OVA"
echo "=============================================="

declare -A RESULTS

for vm in "${SELECTED_VMS[@]}"; do
    ova_file="${OUTPUT_DIR}/${vm}.ova"
    echo "[$vm] Exportando → $ova_file ..."
    echo "  (esto puede tomar varios minutos)"

    if "$VBOXMANAGE" export "$vm" -o "$ova_file" --ovf10 --options=manifest 2>/dev/null; then
        if [ -f "$ova_file" ]; then
            size=$(du -m "$ova_file" | cut -f1)
            RESULTS[$vm]="OK|${size}"
            echo "  ✓ $vm exportado: ${size} MB"
        else
            RESULTS[$vm]="ERROR|0"
            echo "  ✗ $vm: archivo no encontrado"
        fi
    else
        RESULTS[$vm]="ERROR|0"
        echo "  ✗ $vm: error durante exportación"
    fi
    echo ""
done

# ── Resumen ─────────────────────────────────────
echo "=============================================="
echo "  RESUMEN"
echo "=============================================="

TOTAL_MB=0
for vm in "${SELECTED_VMS[@]}"; do
    IFS='|' read -r status size <<< "${RESULTS[$vm]}"
    icon="✗"
    [ "$status" = "OK" ] && icon="✓"
    echo "  $icon $vm → ${size} MB"
    TOTAL_MB=$((TOTAL_MB + size))
done

echo ""
echo "  Total: ${TOTAL_MB} MB en ${#SELECTED_VMS[@]} archivo(s)"
echo "  Destino: $OUTPUT_DIR"
echo ""

if [ "$SKIP_CLEANUP" = true ]; then
    echo "[NOTA] Se omitió la limpieza (--skip-cleanup)."
fi
echo ""
echo "Para importar en VirtualBox:"
echo "  1. VirtualBox → Archivo → Importar servicio virtualizado"
echo "  2. Crear red Host-Only: 192.168.56.1 / 255.255.255.0"
echo "  3. Iniciar VMs (orden: nodo01 → nodo02 → nodo03)"
echo "  4. SSH: bddadmin / bddadmin"
echo "  5. MariaDB root: LabAdmin_2025!"
