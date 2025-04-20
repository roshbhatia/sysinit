#!/usr/bin/env bash
# This script ensures ZSH plugins are installed in the user's home directory

set -e

PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$PLUGIN_DIR"

echo "Installing ZSH plugins to $PLUGIN_DIR..."

# Install fzf-tab
if [[ ! -d "$PLUGIN_DIR/fzf-tab" ]]; then
  echo "Installing fzf-tab..."
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git "$PLUGIN_DIR/fzf-tab"
else
  echo "fzf-tab already installed"
fi

# Install zsh-autosuggestions
if [[ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]]; then
  echo "Installing zsh-autosuggestions..."
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_DIR/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed"
fi

# Install fast-syntax-highlighting
if [[ ! -d "$PLUGIN_DIR/fast-syntax-highlighting" ]]; then
  echo "Installing fast-syntax-highlighting..."
  git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_DIR/fast-syntax-highlighting"
else
  echo "fast-syntax-highlighting already installed"
fi

echo "Done installing ZSH plugins"
