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
    local lock_file="/tmp/zsh_extras_$USER.lock"
    
    # Check lock file
    [[ -f "$lock_file" ]] && return
    [[ ! -d "$extras_dir" ]] && return
    
    # Create lock file
    touch "$lock_file"
    
    {
        # Combine and source extras
        local tmp_file=$(mktemp)
        echo "#!/usr/bin/env zsh" > "$tmp_file"
        
        # Add extras
        find "$extras_dir" -type f -name "*.sh" -not -name "loglib.sh" -exec cat {} \; >> "$tmp_file" 2>/dev/null
        find "$extras_dir/bin" -type f -exec cat {} \; >> "$tmp_file" 2>/dev/null
        
        # Source combined file
        source "$tmp_file" >/dev/null 2>&1
        rm -f "$tmp_file"
        rm -f "$lock_file"
    } >/dev/null 2>&1
}

# Start async load with proper job management
(
    _load_extras
    disown
) &>/dev/null &

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