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

# General settings
[ -f "$XDG_CONFIG_HOME/zsh/paths.sh" ] && source "$XDG_CONFIG_HOME/zsh/paths.sh"

unset MAILCHECK
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ZSH_DISABLE_COMPFIX="true"
export PAGER="bat --pager=always --color=always"
export EDITOR="nvim"

# Load essential configs first
source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Source core files in specific order (loglib must be first)
source "$XDG_CONFIG_HOME/zsh/loglib.sh"    # Load logging first
source "$XDG_CONFIG_HOME/zsh/paths.sh"      # Load paths
source "$XDG_CONFIG_HOME/zsh/style.sh"      # Load styling
source "$XDG_CONFIG_HOME/zsh/fzf.sh"        # Load fzf
source "$XDG_CONFIG_HOME/zsh/completions.sh"   # Load completions
source "$XDG_CONFIG_HOME/zsh/notifications.sh" # Load notifications
source "$XDG_CONFIG_HOME/zsh/shift-select.sh"  # Load shift-select

# Load all extras
_load_extras() {
    local extras_dir="$XDG_CONFIG_HOME/zsh/extras"
    [[ ! -d "$extras_dir" ]] && return

    # Create temp file for loading
    local tmp_file=$(mktemp)
    
    # Concatenate all extras into a single temp file
    {
        # First load any direct .sh files in extras
        for module in "$extras_dir"/*.sh; do
            [[ -f "$module" ]] && cat "$module" >> "$tmp_file"
        done

        # Then load any scripts in extras/bin if it exists
        local bin_dir="$extras_dir/bin"
        if [[ -d "$bin_dir" ]]; then
            for script in "$bin_dir"/*; do
                [[ -f "$script" ]] && cat "$script" >> "$tmp_file"
            done
        fi
    } 2>/dev/null

    # Source the combined file and clean up
    source "$tmp_file" 2>/dev/null
    rm -f "$tmp_file"
}

# Load extras in background without output
{ (_load_extras & ) } >/dev/null 2>&1

# Fix TERM_PROGRAM unbound variable issue
if [ -z "$TERM_PROGRAM" ]; then
  export TERM_PROGRAM=""
fi

# Disable ctrl+s to freeze terminal
stty stop undef

# Word/Line navigation using CTRL + hjk;
bindkey '^h' beginning-of-line    # CTRL + h for beginning of line
bindkey '^j' backward-word        # CTRL + j for back word
bindkey '^k' forward-word         # CTRL + k for forward word
bindkey '^;' end-of-line         # CTRL + ; for end of line


# Run macchina in WezTerm's main pane
if [ "$WEZTERM_PANE" = "0" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi

_evalcache starship init zsh