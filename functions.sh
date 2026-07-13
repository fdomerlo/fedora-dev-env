#!/bin/bash

# functions.sh - Orquestador de Entornos (Antigravity / uv / DevContainers)
# Agregar a ~/.zshrc: source ~/Scripts/functions.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables globales
CURRENT_USER=$(whoami)
DEV_BASE_DIR="$HOME/workspace/github.com/$CURRENT_USER"

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# =============================================================================
# VALIDACIÓN DE HERRAMIENTAS GLOBALES (HOST)
# =============================================================================

_check_global_tools() {
    if ! command -v uv &> /dev/null; then
        log_error "Motor 'uv' no encontrado en el host. Instálalo: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE NAVEGACIÓN Y GESTIÓN DE DIRECTORIOS
# =============================================================================

devdir() {
    cd "$DEV_BASE_DIR" || {
        log_error "Directorio de desarrollo no encontrado: $DEV_BASE_DIR"
        return 1
    }
}

cdp() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        log_error "Uso: cdp <nombre-proyecto>"
        return 1
    fi
    
    local project_path="$DEV_BASE_DIR/$project_name"
    if [ -d "$project_path" ]; then
        cd "$project_path"
        log_success "Cambiado a proyecto: $project_name"
        
        # Con uv no es estrictamente necesario activar el entorno para ejecutar scripts,
        # pero es útil para que el IDE de la terminal (Zsh) reconozca las rutas.
        if [ -f ".venv/bin/activate" ]; then
            source .venv/bin/activate
            log_info "Entorno virtual de uv activado."
        fi
    else
        log_error "Proyecto no encontrado: $project_name"
        lsdev
        return 1
    fi
}

lsdev() {
    if [ ! -d "$DEV_BASE_DIR" ]; then
        log_warning "Directorio de desarrollo no existe: $DEV_BASE_DIR"
        return 1
    fi
    
    log_info "Proyectos en $DEV_BASE_DIR:"
    find "$DEV_BASE_DIR" -maxdepth 1 -type d -not -path "$DEV_BASE_DIR" | \
    while read -r dir; do
        local project_name=$(basename "$dir")
        local flags=""
        [ -d "$dir/.git" ] && flags="$flags [Git]"
        [ -d "$dir/.devcontainer" ] && flags="$flags [DevContainer]"
        [ -d "$dir/.venv" ] && flags="$flags [uv-venv]"
        echo "  📁 $project_name$flags"
    done
}

# =============================================================================
# FUNCIONES DE CLONADO
# =============================================================================

clone_repo() {
    local repo_url=$1
    local use_ssh=${2:-false}

    if [ -z "$repo_url" ]; then log_error "Uso: clone_repo <url> [true|false para SSH]"; return 1; fi

    local normalized_url=$(echo "$repo_url" | sed -e 's/^https:\/\///' -e 's/^git@//' -e 's/:/\//')
    local host=$(echo "$normalized_url" | cut -d'/' -f1)
    local org=$(echo "$normalized_url" | cut -d'/' -f2)
    local repo=$(echo "$normalized_url" | cut -d'/' -f3 | sed 's/.git$//')

    local target_dir="$HOME/workspace/$host/$org/$repo"
    mkdir -p "$(dirname "$target_dir")"

    if [ "$use_ssh" = "true" ]; then repo_url="git@$host:$org/$repo.git"; fi

    log_info "Clonando en: $target_dir"
    git clone "$repo_url" "$target_dir" && { cd "$target_dir"; log_success "Repositorio clonado"; }
}

clone_short() {
    local shorthand=$1
    local use_ssh=${2:-false}
    
    if [ -z "$shorthand" ]; then log_error "Uso: clones <usuario/repo> [true|false]"; return 1; fi
    
    local host="github.com"
    local path="$shorthand"
    
    if [[ $shorthand == *"/"*"/"* ]]; then
        host=$(echo "$shorthand" | cut -d'/' -f1)
        path=$(echo "$shorthand" | cut -d'/' -f2-)
    fi
    
    local org=$(echo "$path" | cut -d'/' -f1)
    local repo=$(echo "$path" | cut -d'/' -f2)
    local target_dir="$HOME/workspace/$host/$org/$repo"
    
    local url="https://$host/$org/$repo.git"
    [[ $use_ssh == "true" ]] && url="git@$host:$org/$repo.git"
    
    log_info "Clonando: $url"
    mkdir -p "$(dirname "$target_dir")"
    git clone "$url" "$target_dir" && { cd "$target_dir"; log_success "Repositorio clonado"; }
}

# =============================================================================
# CREACIÓN DE PROYECTOS DJANGO DE ALTO RENDIMIENTO
# =============================================================================

create_django_project() {
    _check_global_tools || return 1

    local project_name=$1
    
    if [ -z "$project_name" ]; then
        log_error "Uso: djcreate <project-name>"
        return 1
    fi
    
    if [[ ! "$project_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_error "Nombre inválido. Solo minúsculas, números y guiones."
        return 1
    fi
    
    local project_path="$DEV_BASE_DIR/$project_name"
    local django_app_name=$(echo "$project_name" | tr '-' '_')
    
    if [ -d "$project_path" ]; then
        log_error "El proyecto ya existe en $project_path"
        return 1
    fi
    
    log_info "🚀 Orquestando proyecto Django (uv + Ruff): $project_name"
    
    mkdir -p "$project_path"
    cd "$project_path"

    # 1. Inicialización ultra rápida con uv
    log_info "Generando entorno y pyproject.toml..."
    uv init --python 3.12 > /dev/null
    
    # 2. Agregar dependencias (Producción)
    log_info "Inyectando dependencias base..."
    uv add django django-environ djangorestframework "psycopg[binary]" > /dev/null
    
    # 3. Agregar dependencias (Desarrollo)
    log_info "Inyectando motor Ruff para QA..."
    uv add --dev ruff pytest-django > /dev/null

    # 4. Scaffolding Django
    log_info "Construyendo estructura Django..."
    uv run django-admin startproject config src
    
    # 5. Infraestructura como Código
    _create_devcontainer
    _create_makefile
    _create_env_example "$project_name" "$django_app_name"
    _create_gitignore
    _create_agents_manifest

    # 6. Git
    git init > /dev/null
    git add .
    git commit -m "chore: initial commit (Django + uv + Ruff)" > /dev/null
    
    log_success "✅ Arquitectura desplegada."
    log_info "Siguiente paso: Abre Antigravity IDE y selecciona 'Reopen in Container' (Opcional, los agentes pueden operar localmente)."
    log_info "$ antigravity ."
}

# =============================================================================
# GENERADORES DE CÓDIGO Y CONFIGURACIÓN
# =============================================================================

_create_devcontainer() {
    mkdir -p .devcontainer
    cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Django Dev",
  "image": "mcr.microsoft.com/devcontainers/python:1-3.12-bookworm",
  "features": {
    "ghcr.io/devcontainers-contrib/features/uv:1": {}
  },
  "customizations": {
    "vscode": {
      "settings": {
        "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
        "editor.formatOnSave": true,
        "[python]": {
          "editor.defaultFormatter": "charliermarsh.ruff",
          "editor.codeActionsOnSave": {
            "source.fixAll": "explicit",
            "source.organizeImports": "explicit"
          }
        }
      },
      "extensions": [
        "ms-python.python",
        "charliermarsh.ruff",
        "batisteo.vscode-django"
      ]
    }
  },
  "postCreateCommand": "uv sync",
  "forwardPorts": [8000],
  "remoteUser": "vscode"
}
EOF
}

_create_makefile() {
    cat > Makefile << 'EOF'
.PHONY: run migrate makemigrations lint format shell

run:
	uv run python src/manage.py runserver

migrate:
	uv run python src/manage.py migrate

mm:
	uv run python src/manage.py makemigrations

lint:
	uv run ruff check src/

format:
	uv run ruff check --fix src/
	uv run ruff format src/

shell:
	uv run python src/manage.py shell
EOF
}

_create_env_example() {
    local project_name=$1
    local django_app_name=$2
    cat > .env.example << EOF
# Django
DEBUG=True
SECRET_KEY=dev-secret-key-change-me
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# Base de datos (Local SQLite por defecto)
DATABASE_URL=sqlite:///db.sqlite3

# Para desarrollo con LXC Postgres en Proxmox:
# DATABASE_URL=postgres://appuser:password@10.0.0.10:5432/appdb
EOF
    cp .env.example .env
}

_create_gitignore() {
    cat > .gitignore << 'EOF'
.venv/
__pycache__/
*.pyc
.env
db.sqlite3
.pytest_cache/
.ruff_cache/
EOF
}

_create_agents_manifest() {
    local target_file=".agents"
    local template_file="$HOME/Scripts/agents.md"

    if [ -f "$template_file" ]; then
        # Copiar la plantilla central al proyecto local
        cp "$template_file" "$target_file"
        log_info "Manifiesto de agentes inyectado desde plantilla central."
    else
        # Fallback de seguridad por si el archivo global no existe
        cat > "$target_file" << 'EOF'
# REGLAS BASE DE AGENTE
1. Usar exclusivamente `uv` para dependencias. Prohibido `pip`.
2. Usar exclusivamente `ruff` para linting y formateo.
3. Ejecutar comandos dentro de `uv run`.
EOF
        log_warning "Plantilla global no encontrada en $template_file. Se creó un .agents básico."
    fi

    # Crear enlaces simbólicos silenciosos para que los motores de IA del IDE
    # detecten las reglas automáticamente sin importar el fork que uses.
    ln -s "$target_file" .cursorrules 2>/dev/null || true
    ln -s "$target_file" .windsurfrules 2>/dev/null || true
}

# =============================================================================
# ALIASES Y SHORTCUTS
# =============================================================================

alias djcreate='create_django_project'
alias clone='clone_repo'
alias clones='clone_short'
alias projects='lsdev'

dev_help() {
    echo -e "${BLUE}Orquestador de Desarrollo Activo (Antigravity):${NC}"
    echo "  dev                    - Ir al directorio raíz"
    echo "  cdp <proyecto>         - Entrar a un proyecto"
    echo "  projects               - Listar repositorios locales"
    echo "  djcreate <nombre>      - Crear stack Django moderno (uv + Ruff)"
    echo "  clone <url>            - Clonar vía URL"
    echo "  clones <user/repo>     - Clonar vía shorthand Github"
}

echo -e "${BLUE}Entorno de orquestación local cargado. Usa 'dev_help'.${NC}"