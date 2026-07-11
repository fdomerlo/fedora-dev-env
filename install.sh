#!/usr/bin/env bash
set -euo pipefail

TARGET="$HOME/.infra-dev-env"
BIN="$HOME/.local/bin"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

echo "==> Installing infra-dev-env"

mkdir -p "$TARGET" "$BIN"

rsync -a --delete ./ "$TARGET/"

ln -sf "$TARGET/devctl" "$BIN/devctl"
chmod +x "$TARGET/devctl"

# PATH
grep -q ".local/bin" "$HOME/.bashrc" || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# ZSH base
echo "==> Installing base Zsh"
sudo dnf install -y zsh

cp "$TARGET/shell/zshrc" "$HOME/.zshrc"
chsh -s "$(which zsh)"

if [ "$NON_INTERACTIVE" = "true" ]; then
  devctl host setup
  devctl host snapper
  devctl host swap
  exit 0
fi

echo ""
echo "✅ Installation complete"
echo ""

# --------------------------------------------------
# INTERACTIVE MENU
# --------------------------------------------------

while true; do
  echo "========= DEV ENV ========="
  echo "1) Host setup"
  echo "2) Snapper"
  echo "3) Swap"
  echo "4) Create Python box"
  echo "5) Create PHP box"
  echo "6) Install Oh My Zsh (optional)"
  echo "7) Doctor"
  echo "8) Exit"
  echo "==========================="
  read -rp "Choose: " opt

  case $opt in
    1) devctl host setup ;;
    2) devctl host snapper ;;
    3) devctl host swap ;;
    4) devctl box rebuild python ;;
    5) devctl box rebuild php ;;
    6) bash "$TARGET/shell/ohmyzsh.sh" ;;
    7) devctl doctor ;;
    8) break ;;
    *) echo "Invalid option" ;;
  esac
done

if [ -z "$NON_INTERACTIVE" ]; then
  echo ""
  echo "=============================="
  echo "   infra-dev-env listo 🚀"
  echo "=============================="
  echo ""
  echo "1) Setup host completo"
  echo "2) Crear box Python"
  echo "3) Crear box PHP"
  echo "4) Instalar Oh My Zsh"
  echo "5) Salir"
  echo ""

  read -rp "Elegí una opción: " opt

  case $opt in
    1) devctl host setup ;;
    2) devctl box create python ;;
    3) devctl box create php ;;
    4) devctl shell ohmyzsh ;;
    *) echo "Listo 👍" ;;
  esac
fi
