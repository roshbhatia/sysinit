#!/usr/bin/env zsh
# shellcheck disable=all
# Tool-specific integrations

# nix-your-shell integration
if command -v nix-your-shell &> /dev/null; then
  if (($ + functions[_evalcache])); then
    _evalcache nix-your-shell zsh
  else
    nix-your-shell zsh | source /dev/stdin
  fi
fi

# grc colorization
[[ -s "/usr/local/etc/grc.zsh" ]] && source /usr/local/etc/grc.zsh
