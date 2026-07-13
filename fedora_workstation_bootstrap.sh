#!/usr/bin/env bash
# ==============================================================================
# fedora_workstation_bootstrap.sh
# Aprovisionamiento Idempotente para Host de Ingeniería en Fedora
# ==============================================================================

set -euo pipefail

# --- Colores y Variables ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

_log()  { echo -e "\n${CYAN}==>${RESET} ${CYAN}$1${RESET}"; }
_ok()   { echo -e "${GREEN} ✓${RESET}  $1"; }
_warn() { echo -e "${YELLOW} ⚠️${RESET}  $1"; }
_die()  { echo -e "\n${RED}[FATAL] $1${RESET}" >&2; exit 1; }

[[ $EUID -eq 0 ]] || _die "Este script debe ejecutarse como root (sudo)."
SUDO_USER="${SUDO_USER:-$(logname)}"
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)

_log "1. Actualizando sistema base (DNF)"
dnf upgrade --refresh -y -q || true
_ok "Sistema actualizado."

# ==============================================================================
# FASE 2: REPOSITORIOS DE TERCEROS
# ==============================================================================
_log "2. Configurando repositorios de orquestación explícitos (RPM)"

if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    _ok "Repositorio de VS Code configurado."
fi

if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
    cat <<EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    _ok "Repositorio de Google Chrome configurado."
fi

# ==============================================================================
# FASE 3: INSTALACIÓN DE PAQUETES CORE Y ORQUESTACIÓN
# ==============================================================================
_log "3. Instalando paquetes del host inmutable"

HOST_PKGS=(
    zsh curl git ncdu 7zip gnome-tweaks 
    distrobox podman podman-compose podman-docker
    code google-chrome-stable gh
)

dnf install -y "${HOST_PKGS[@]}"

if ! command -v dbeaver &> /dev/null; then
    _log "Instalando DBeaver CE..."
    dnf install -y https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
fi

_ok "Paquetes base de infraestructura instalados."

# ==============================================================================
# FASE 4: EXPERIENCIA DE USUARIO (ZSH, PLUGINS Y GNOME)
# ==============================================================================
_log "4. Configurando Zsh y entorno de escritorio para $SUDO_USER"

CURRENT_SHELL=$(getent passwd "$SUDO_USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)" "$SUDO_USER" || true
    _ok "Zsh configurado como shell predeterminado."
fi

OMZ_DIR="$USER_HOME/.oh-my-zsh"
if [ ! -d "$OMZ_DIR" ]; then
    sudo -u "$SUDO_USER" env HOME="$USER_HOME" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended" || true
    _ok "Oh My Zsh instalado."
fi

CUSTOM_PLUGINS_DIR="$OMZ_DIR/custom/plugins"
sudo -u "$SUDO_USER" mkdir -p "$CUSTOM_PLUGINS_DIR"

# Idempotencia estricta: Clonar si no existe, hacer pull si existe
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$CUSTOM_PLUGINS_DIR/$plugin" ]; then
        sudo -u "$SUDO_USER" git clone --depth 1 "https://github.com/zsh-users/$plugin.git" "$CUSTOM_PLUGINS_DIR/$plugin" >/dev/null 2>&1
    else
        sudo -u "$SUDO_USER" git -C "$CUSTOM_PLUGINS_DIR/$plugin" pull >/dev/null 2>&1
    fi
done

# ==============================================================================
# FASE 5: DESPLIEGUE DECLARATIVO DE CONFIGURACIONES (.zshrc)
# ==============================================================================
_log "5. Desplegando archivo de configuración .zshrc"

# Sobrescribe declarativamente el .zshrc garantizando el estado exacto deseado.
sudo -u "$SUDO_USER" cat << 'EOF' > "$USER_HOME/.zshrc"
# ---------------------------------------------------------------------------
# ZSH y Oh My Zsh - Configuración Principal
# ---------------------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

export LC_ALL=es_AR.utf8
export LANG=es_AR.utf8
export LANGUAGE=es_AR.utf8

plugins=(
  git
  common-aliases
  extract
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# CONFIGURACIÓN DE DESARROLLO: DISTROBOX / DEVCONTAINER (Host + Contenedores)
# =============================================================================

export PATH="/usr/local/bin:$HOME/bin:$PATH"

if [ -f ~/Scripts/functions.sh ]; then
    source ~/Scripts/functions.sh
fi
   
PROMPT=$'📦[%{\e[0;33m%}$CONTAINER_ID%{\e[0m%}] %{\e[0;36m%}%n%{\e[0m%} %~ $ '

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

if [ -f "$HOME/.local/share/../bin/env" ]; then
    source "$HOME/.local/share/../bin/env"
fi

if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

PROMPT=$'%{\e[0;36m%}%n%{\e[0m%} %~ $ '

export PATH=$HOME/.opencode/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
_ok "Archivo .zshrc aprovisionado."

# ==============================================================================
# FASE 6: INSTALACIÓN DE GESTORES DE VERSIONES (uv, fnm, sdkman)
# ==============================================================================
_log "6. Instalando gestores de entorno (espacio de usuario)"

# Instalación de uv
if ! sudo -u "$SUDO_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/bin:$PATH" command -v uv &> /dev/null; then
    _log "Instalando motor uv..."
    sudo -u "$SUDO_USER" env HOME="$USER_HOME" sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
    _ok "uv instalado."
else
    _ok "uv ya se encuentra instalado."
fi

# Instalación de fnm (Node.js)
if [ ! -d "$USER_HOME/.local/share/fnm" ] && ! sudo -u "$SUDO_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/share/fnm:$PATH" command -v fnm &> /dev/null; then
    _log "Instalando fnm..."
    sudo -u "$SUDO_USER" env HOME="$USER_HOME" sh -c "curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell"
    _ok "fnm instalado."
else
    _ok "fnm ya se encuentra instalado."
fi

# Instalación de SDKMAN (Java/Groovy)
if [ ! -d "$USER_HOME/.sdkman" ]; then
    _log "Instalando sdkman..."
    sudo -u "$SUDO_USER" env HOME="$USER_HOME" sh -c "curl -s \"https://get.sdkman.io?rcupdate=false\" | bash"
    _ok "sdkman instalado."
else
    _ok "sdkman ya se encuentra instalado."
fi

# GNOME Extensions
dnf install -y gnome-shell-extension-dash-to-dock || true

echo -e "\n${GREEN}✅ Aprovisionamiento de Workstation completado.${RESET}"
echo -e "${YELLOW}NOTA: Cierra sesión y vuelve a entrar para activar Zsh, las herramientas de usuario y las extensiones de GNOME.${RESET}"
