#!/usr/bin/env zsh
# shellcheck disable=all

# Cache oh-my-posh init for faster shell startup
if (($ + functions[_evalcache])); then
  _evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
else
  eval "$(oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json")"
fi
