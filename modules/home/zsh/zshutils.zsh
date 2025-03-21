#!/usr/bin/env zsh
# shellcheck disable=all

# Load all utility scripts from the extras directory
ZSH_UTILS_DIR="$HOME/.config/zsh/extras"

# Basic functions
function mkcd() {
  mkdir -p "$1" && cd "$1";
}

# Source all utility scripts
if [[ -d "$ZSH_UTILS_DIR" ]]; then
  for util_script in "$ZSH_UTILS_DIR"/*.sh; do
    if [[ -f "$util_script" ]]; then
      source "$util_script"
    fi
  done
else
  echo "ZSH utilities directory not found: $ZSH_UTILS_DIR"
fi