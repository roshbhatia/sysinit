#!/usr/bin/env zsh
# shellcheck disable=all

if type _evalcache &> /dev/null; then
  _evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
else
  eval "$(oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json")"
fi
