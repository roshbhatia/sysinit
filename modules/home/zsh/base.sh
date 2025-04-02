#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore
#       ___           ___           ___           ___           ___
#      /  /\         /  /\         /__/\         /  /\         /  /\
#     /  /::|       /  /:/_        \  \:\       /  /::\       /  /:/
#    /  /:/:|      /  /:/ /\        \__\:\     /  /:/\:\     /  /:/
#   /  /:/|:|__   /  /:/ /::\   ___ /  /::\   /  /:/~/:/    /  /:/  ___
#  /__/:/ |:| /\ /__/:/ /:/\:\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/  /  /\
#  \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/
#      |  |:/:/   \  \::/ /:/   \  \::/       \  \::/~~~~   \  \:\  /:/
#      |  |::/     \__\/ /:/     \  \:\        \  \:\        \  \:\/:/
#      |  |:/        /__/:/       \  \:\        \  \:\        \  \::/
#      |__|/         \__\/         \__\/         \__\/         \__\/

# Skip all initialization for non-interactive shells
[[ ! -o interactive ]] && return

# General settings
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_DISABLE_COMPFIX="true"
unset MAILCHECK

# Fast compinit with cached completions
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  # Only check cache once per day
  compinit -i -C
else
  compinit -i
fi

# Async load tool initializations
async_init() {
  # Source paths first since other configs might need them
  [ -f "$XDG_CONFIG_HOME/zsh/paths.sh" ] && source "$XDG_CONFIG_HOME/zsh/paths.sh"

  # Load core configs asynchronously
  {
    for config in "$XDG_CONFIG_HOME/zsh"/{style,fzf,notifications,homebrew}.sh; do
      [ -f "$config" ] && source "$config"
    done
    
    # Source additional configs
    [ -f ~/.zshenv ] && source ~/.zshenv
    [ -f ~/.zshutils ] && source ~/.zshutils
  } &!
}

# Lazy load function
function lazy_load() {
  local cmd="$1"
  shift
  if command -v "$cmd" &> /dev/null; then
    eval "$("$cmd" "$@")"
  fi
}

# Lazy load tools on first use
direnv() { unfunction direnv && lazy_load direnv hook zsh; direnv "$@" }
gh() { unfunction gh && lazy_load gh copilot alias -- zsh; gh "$@" }
is() { unfunction is && lazy_load is init zsh; is "$@" }

# Critical UI elements load immediately
command -v starship &> /dev/null && eval "$(starship init zsh)"

# Disable ctrl+s freeze
stty stop undef

# Run macchina only in main pane and after prompt
if [ "$WEZTERM_PANE" = "0" ]; then
  function precmd() {
    if [ -n "$MACCHINA_THEME" ]; then
      macchina --theme "$MACCHINA_THEME"
    else
      macchina --theme rosh
    fi
    unfunction precmd
  }
fi

# Initialize async loading
async_init