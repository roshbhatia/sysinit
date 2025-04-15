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

[[ -f "$HOME/.sysinit-debug" ]] && export SYSINIT_DEBUG=1
[[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof

ZSH_DISABLE_COMPFIX="true"

autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

unset MAILCHECK

export EDITOR="nvim"
export PAGER="bat --pager=always --color=always"
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export ZSH_CORE_PRE_DIR="$XDG_CONFIG_HOME/zsh/core.pre"
export ZSH_CORE_MAIN_DIR="$XDG_CONFIG_HOME/zsh/core.main"
export ZSH_EXTRAS_DIR="$XDG_CONFIG_HOME/zsh/extras"

source_shell_files() {
  local dir=$1
  local name=${2:-$(basename "$dir")}

  if [[ ! -d "$dir" ]]; then
    [[ -n "$SYSINIT_DEBUG" ]] && echo "Warning: Directory $name not found"
    return 1
  fi

  local files=("$dir"/*.sh(N))
  if (( ${#files[@]} == 0 )); then
    [[ -n "$SYSINIT_DEBUG" ]] && echo "Warning: No shell files found in $name"
    return 0
  fi

  local file
  for file in "${files[@]}"; do
    # Get compiled file path
    local compiled="${file}.zwc"
    
    # Compile if compiled file doesn't exist or source is newer
    if [[ ! -f "$compiled" || "$file" -nt "$compiled" ]]; then
      [[ -n "$SYSINIT_DEBUG" ]] && echo "Compiling: $file"
      zcompile "$file"
    fi

    # Source the original file (zsh automatically uses compiled version)
    [[ -n "$SYSINIT_DEBUG" ]] && echo "Sourcing: $file"
    source "$file"
  done
}

source_shell_files "$ZSH_CORE_PRE_DIR" "core.pre"
source_shell_files "$ZSH_CORE_MAIN_DIR" "core.main"
source_shell_files "$ZSH_EXTRAS_DIR" "extras"

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
[[ -n "$SYSINIT_DEBUG" ]] && zprof
