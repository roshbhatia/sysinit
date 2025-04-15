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

unset MAILCHECK

export EDITOR="nvim"
export PAGER="bat --pager=always --color=always"
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export ZSH_DISABLE_COMPFIX="true"
export ZSH_UTILS_DIR="$XDG_CONFIG_HOME/zsh/extras"

for core in "pre" "main"; do
  if [[ -d "$XDG_CONFIG_HOME/zsh/core.$core" ]]; then
    for file in "$XDG_CONFIG_HOME/zsh/core.$core"/*.sh(N); do
      source "$file"
    done
  else
    echo "Warning: $XDG_CONFIG_HOME/zsh/core.$core directory not found"
  fi
done


if [[ -d "$ZSH_UTILS_DIR" ]]; then
  for util_script in "$ZSH_UTILS_DIR"/*.sh; do
    if [[ -f "$util_script" ]]; then
      source "$util_script"
    fi
  done
else
  echo "Warning: $ZSH_UTILS_DIR directory not found"
fi

# Disable ctrl+s to freeze terminal
stty stop undef

bindkey '^h' beginning-of-line    # CTRL + h for beginning of line
bindkey '^j' backward-word        # CTRL + j for back word
bindkey '^k' forward-word         # CTRL + k for forward word
bindkey '^;' end-of-line          # CTRL + ; for end of line

if [ "$WEZTERM_PANE" = "0" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi

eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/zash.omp.json)"
