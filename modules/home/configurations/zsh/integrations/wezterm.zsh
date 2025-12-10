#!/usr/bin/env zsh
# shellcheck disable=all
# Wezterm shell integration
# Sources the official wezterm shell integration script

[[ -z $WEZTERM_UNIX_SOCKET ]] && return 0

if [[ -f "$WEZTERM_CONFIG_DIR/shell-integration.sh" ]]; then
  source "$WEZTERM_CONFIG_DIR/shell-integration.sh"
elif [[ -f "/Applications/WezTerm.app/Contents/Resources/wezterm.sh" ]]; then
  source "/Applications/WezTerm.app/Contents/Resources/wezterm.sh"
elif command -v wezterm &> /dev/null; then
  eval "$(wezterm shell-completion --shell zsh 2> /dev/null || true)"
fi
