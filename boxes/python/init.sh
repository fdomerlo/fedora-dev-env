#!/usr/bin/env bash
# boxes/python/init.sh - Aprovisionamiento automático interno para el contenedor Python
set -euo pipefail

echo "==> [Contenedor] Iniciando configuración interna del entorno Ubuntu"

# 1. Actualizar paquetes del sistema e instalar dependencias de compilación nativas
echo "==> [Contenedor] Instalando dependencias de desarrollo vía APT..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    software-properties-common \
    python3-pygments \
    jq \
    zip \
    unzip

# 2. Inicializar FNM (que ya vive en el $HOME compartido) para asegurar Node.js
echo "==> [Contenedor] Configurando entorno de Node.js..."
export PATH="$HOME/.local/bin:$PATH"

if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
    # Asegurar que el contenedor tenga una versión de Node funcional para los CLI de IA
    fnm install --lts
    fnm use --lts
else
    echo "Falta FNM en el Host. Asegúrate de correr 'make host' primero." >&2
    exit 1
fi

# 3. Instalar Orquestadores de IA globales dentro del contenedor
echo "==> [Contenedor] Instalando orquestadores de IA locales..."

# Claude Code
if ! command -v claude &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
fi

# Gemini CLI
if ! command -v gemini &> /dev/null; then
    npm install -g @google/generative-ai-cli
fi

# OpenCode CLI
if ! command -v opencode &> /dev/null; then
    npm install -g opencode
fi

echo "==> [Contenedor] Entorno interno listo."