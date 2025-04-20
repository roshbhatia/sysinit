#!/usr/bin/env zsh
# shellcheck disable=all
_evalcache /opt/homebrew/bin/brew shellenv
_evalcache atuin init zsh --disable-up-arrow
_evalcache kubectl completion zsh
_evalcache docker completion zsh
_evalcache direnv hook zsh
_evalcache gh copilot alias -- zsh

extras_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"
if [[ -d $extras_dir ]]; then
  for f in "$extras_dir"/*.sh; do
    [[ -r $f ]] && source "$f"
  done
fi
