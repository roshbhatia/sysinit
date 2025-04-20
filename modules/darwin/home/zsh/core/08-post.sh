#!/usr/bin/env zsh
# shellcheck disable=all
_evalcache /opt/homebrew/bin/brew shellenv
_evalcache atuin init zsh --disable-up-arrow
_evalcache kubectl completion zsh
_evalcache docker completion zsh
_evalcache direnv hook zsh
_evalcache gh copilot alias -- zsh

# Load extras files if they exist (avoid "no matches found" error)
extras_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"
if [[ -d $extras_dir ]]; then
  # Temporarily disable "no matches found" error
  setopt +o nomatch
  
  # Use a safer approach with find to list available files
  for f in $(find "$extras_dir" -name "*.sh" -type f 2>/dev/null); do
    if [[ -r $f ]]; then
      source "$f"
    fi
  done
  
  # Reset to previous setting
  setopt -o nomatch
fi
