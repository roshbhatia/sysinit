#!/usr/bin/env zsh
# shellcheck disable=all
# Load extra configuration files from ~/.config/zsh/extras/

EXTRAS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"

if [[ -d $EXTRAS_DIR ]]; then
  setopt nullglob
  local extra_files=("$EXTRAS_DIR"/*.sh "$EXTRAS_DIR"/*.zsh)
  unsetopt nullglob

  for file in "${extra_files[@]}"; do
    if (($ + functions[cached_source])); then
      cached_source "$file"
    else
      source "$file"
    fi
  done
fi

# Load secrets if present
[[ -f "$HOME/.zshsecrets" ]] && source "$HOME/.zshsecrets"
