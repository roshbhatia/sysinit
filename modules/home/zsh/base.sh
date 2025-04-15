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

autoload -Uz zcompare

zcompare() {
    if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc) ]]; then
        [[ -n "$SYSINIT_DEBUG" ]] && echo "Compiling ${1}"
        zcompile "${1}"
    fi
}

source_compiled_if_exists() {
    local source_file=$1
    local zwc_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/compiled"
    local rel_path="${source_file#/}"
    local zwc_file="$zwc_dir/$rel_path.zwc"
    
    # Create directory structure if it doesn't exist
    mkdir -p "$(dirname "$zwc_file")"
    
    # Use zcompare for compilation check
    if [[ -s ${source_file} && ( ! -s ${zwc_file} || ${source_file} -nt ${zwc_file}) ]]; then
        [[ -n "$SYSINIT_DEBUG" ]] && echo "Compiling: $source_file"
        zcompile "$zwc_file" "$source_file"
    fi
    
    [[ -n "$SYSINIT_DEBUG" ]] && echo "Sourcing: $source_file"
    source "$source_file"
}

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
    source_compiled_if_exists "$file"
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
