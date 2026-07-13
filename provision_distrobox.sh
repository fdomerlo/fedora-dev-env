#!/bin/bash
set -euo pipefail

# =============================================================================
# SCRIPT DE APROVISIONAMIENTO PARA DISTROBOX (UBUNTU)
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Bloqueo de Seguridad (Protección del Host)
if [ -z "${CONTAINER_ID:-}" ]; then
    log_error "VIOLACIÓN DE ENTORNO: Estás ejecutando esto en Fedora."
    log_error "Debes entrar al contenedor primero: distrobox enter dev-global"
    exit 1
fi

log_info "Iniciando aprovisionamiento del entorno: $CONTAINER_ID"

# 2. Dependencias del Sistema Base (C, Red, Utilidades)
log_info "Actualizando repositorios e instalando paquetería base de Ubuntu..."
sudo apt-get update
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    unzip \
    jq \
    python3-pygments \
    software-properties-common

# 3. Motor de Python y Runtimes Rápidos (uv)
if ! command -v uv &> /dev/null; then
    log_info "Instalando uv (Gestor de Python en Rust)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    log_success "uv ya está instalado. Actualizando..."
    uv self update || true
fi

# 4. Motor de Node.js (fnm)
if ! command -v fnm &> /dev/null; then
    log_info "Instalando fnm (Gestor de versiones de Node.js)..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
else
    log_success "fnm ya está instalado."
fi

# Inyectar variables temporales para usar fnm y npm en este mismo script
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
eval "$(fnm env)"

# 5. Runtimes de Node
log_info "Asegurando Node.js LTS..."
fnm install --lts
fnm default "lts-latest"
fnm use "lts-latest"

# 6. Orquestadores de IA (Agentic AI)
log_info "Desplegando agentes CLI..."

# Claude Code
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
fi

# Gemini CLI
if ! command -v gemini &> /dev/null; then
    npm install -g @google/generative-ai-cli
fi

# OpenCode (si está disponible vía NPM u otro registro, ajusta según el empaquetado exacto)
if ! command -v opencode &> /dev/null; then
    npm install -g opencode
fi

log_success "Aprovisionamiento de Distrobox completado."
log_info "Ejecuta 'source ~/.zshrc' o reinicia la terminal para que todos los motores estén disponibles."
