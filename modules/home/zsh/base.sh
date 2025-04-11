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

# Source core configurations
for config in "$XDG_CONFIG_HOME/zsh"/{style,fzf,completions,notifications,homebrew,shift-select}.sh; do
  [ -f "$config" ] && source "$config"
done

# Source logging library first
[ -f "$XDG_CONFIG_HOME/zsh/loglib.sh" ] && source "$XDG_CONFIG_HOME/zsh/loglib.sh"

# Load loglib in extras if it exists
[ -f "$XDG_CONFIG_HOME/zsh/extras/loglib.sh" ] && source "$XDG_CONFIG_HOME/zsh/extras/loglib.sh"

# Source zshextras
[ -f ~/.zshextras ] && source ~/.zshextras

# Load utility modules from extras directory
for module in $XDG_CONFIG_HOME/zsh/extras/*.sh; do
  if [[ -f "$module" && "$module" != "$XDG_CONFIG_HOME/zsh/extras/loglib.sh" ]]; then
    source "$module"
  fi
done

# Fix TERM_PROGRAM unbound variable issue
if [ -z "$TERM_PROGRAM" ]; then
  export TERM_PROGRAM=""
fi

# Ensure gettext is in the PATH
if [ -d "/opt/homebrew/opt/gettext/bin" ]; then
  export PATH="/opt/homebrew/opt/gettext/bin:$PATH"
fi

# Tool initializations
command -v direnv &> /dev/null && _evalcache direnv hook zsh
command -v gh &> /dev/null && _evalcache gh copilot alias -- zsh
command -v starship &> /dev/null && _evalcache starship init zsh

# Disable ctrl+s to freeze terminal
stty stop undef

# Word/Line navigation using CTRL + SPACE + hjkl
bindkey '^ h' beginning-of-line    # CTRL + SPACE + h for beginning of line
bindkey '^ j' backward-word       # CTRL + SPACE + j for back word
bindkey '^ k' forward-word        # CTRL + SPACE + k for forward word
bindkey '^ l' end-of-line        # CTRL + SPACE + l for end of line

# Source additional configs if they exist
[ -f ~/.zshenv ] && source ~/.zshenv
[ -f ~/.zshutils ] && source ~/.zshutils

# Run macchina in WezTerm's main pane
if [ "$WEZTERM_PANE" = "0" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi