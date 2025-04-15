#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

ZSH_UTILS_DIR="$XDG_CONFIG_HOME/zsh/extras"

if [[ -d "$ZSH_UTILS_DIR" ]]; then
  for util_script in "$ZSH_UTILS_DIR"/*.sh; do
    if [[ -f "$util_script" ]]; then
      source "$util_script"
    fi
  done
else
  log_error "ZSH utilities directory not found: $ZSH_UTILS_DIR"
fi