#!/usr/bin/env bash
set -euo pipefail

USER_HOME="$HOME"
OMZ_DIR="$USER_HOME/.oh-my-zsh"

echo "==> Installing Oh My Zsh (optional)"

if [ -d "$OMZ_DIR" ]; then
  echo "Already installed"
  exit 0
fi

RUNZSH=no CHSH=no sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Plugins útiles pero livianos
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$OMZ_DIR/custom/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$OMZ_DIR/custom/plugins/zsh-syntax-highlighting"

cat <<EOF > "$USER_HOME/.zshrc"
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
git
zsh-autosuggestions
zsh-syntax-highlighting
)

source \$ZSH/oh-my-zsh.sh

PROMPT='%n@%m %~ %# '
EOF

echo "✅ Oh My Zsh installed"