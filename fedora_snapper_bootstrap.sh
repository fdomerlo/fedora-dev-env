#!/usr/bin/env bash
# ==============================================================================
# fedora_snapper_bootstrap_strict.sh
# Aprovisionamiento de resiliencia BTRFS estricto (Sin COPR / Sin parches GRUB)
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

_log()  { echo -e "\n${CYAN}==>${RESET} ${CYAN}$1${RESET}"; }
_ok()   { echo -e "${GREEN} ✓${RESET}  $1"; }
_die()  { echo -e "\n${RED}[FATAL] $1${RESET}" >&2; exit 1; }

[[ $EUID -eq 0 ]] || _die "Este script debe ejecutarse como root (sudo)."

_log "1. Instalando motor Snapper e integraciones DNF..."
# python3-dnf-plugin-snapper garantiza que DNF siga creando snapshots auto.
dnf install -y snapper python3-dnf-plugin-snapper btrfs-assistant

_log "2. Inicializando topología de Snapper..."
if [ ! -f /etc/snapper/configs/root ]; then
    snapper -c root create-config /
    _ok "Configuración creada para la raíz (root)."
fi

_log "3. Activando demonios de retención automatizada..."
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer
_ok "Timers de limpieza temporal y cuotas activos."

echo -e "\n${GREEN}✅ Aprovisionamiento Base Inmutable completado exitosamente.${RESET}"
