#!/bin/bash

# zsh-fix.sh - Fix for red block highlighting in ZSH
# This script adds configuration to ~/.zshrc to fix the annoying red blocks issue

# ANSI colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration to add to .zshrc
ZSH_CONFIG="
# Fix for WezTerm red block highlights
if [[ \$TERM == *\"wezterm\"* ]]; then
  # Disable bracketed paste which can cause red blocks
  unset zle_bracketed_paste

  # More conservative ZSH syntax highlighting colors
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
  ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
  ZSH_HIGHLIGHT_STYLES[function]='fg=green'
  ZSH_HIGHLIGHT_STYLES[command]='fg=green'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=green'
  ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=blue'
  ZSH_HIGHLIGHT_STYLES[redirection]='fg=blue'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=black,bold'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
  ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=yellow'
  ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[assign]='fg=blue'
  ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta'
  ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta'

  # Fix for error highlighting (the main cause of red blocks)
  ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=blue'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan'
  ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=blue'
  
  # Disable background colors in ZSH highlighting
  ZSH_HIGHLIGHT_STYLES[default]=none
  ZSH_HIGHLIGHT_STYLES[cursor]=underline
  
  # Tell WezTerm we're in a shell
  printf \"\\033]1337;SetUserVar=WEZTERM_SHELL=true\\007\"
  
  # Set terminal title to show current command
  function set_wezterm_title() {
    # Set tab title to current command or 'zsh'
    if [[ -z \$HISTCMD ]]; then
      printf \"\\033]1;zsh\\007\"
    else
      local cmd=\$(fc -ln -1)
      cmd=\$(echo \"\$cmd\" | sed 's/^ *//;s/ *\$//')
      if [[ -n \$cmd ]]; then
        # Extract just the command name, not arguments
        local cmdname=\$(echo \"\$cmd\" | awk '{print \$1}')
        printf \"\\033]1;\$cmdname\\007\"
      fi
    fi
  }
  
  # Add hooks to update title before command execution
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec set_wezterm_title
  
  # Reset title when prompt is shown (after command finishes)
  function reset_wezterm_title() {
    printf \"\\033]1;zsh\\007\"
  }
  add-zsh-hook precmd reset_wezterm_title
fi
"

# Main function
main() {
    echo -e "${BOLD}${BLUE}ZSH Highlighting Fix Installer${NC}\n"
    echo -e "This script will add configuration to your ${YELLOW}~/.zshrc${NC} file"
    echo -e "to fix the ${RED}red block highlighting issue${NC} in WezTerm."
    echo -e "\nIt will also configure ZSH to show the current command in WezTerm tabs.\n"
    
    read -p "Continue? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        echo -e "\n${YELLOW}Installation canceled.${NC}"
        exit 0
    fi
    
    # Check if the configuration is already added
    if grep -q "Fix for WezTerm red block highlights" ~/.zshrc; then
        echo -e "\n${YELLOW}Configuration already exists in ~/.zshrc${NC}"
        read -p "Overwrite? (y/n): " overwrite
        if [[ $overwrite != [yY] ]]; then
            echo -e "\n${YELLOW}Installation canceled.${NC}"
            exit 0
        fi
        
        # Remove existing configuration
        sed -i '/# Fix for WezTerm red block highlights/,/fi/d' ~/.zshrc
    fi
    
    # Add configuration to .zshrc
    echo -e "$ZSH_CONFIG" >> ~/.zshrc
    
    echo -e "\n${GREEN}Installation successful!${NC}"
    echo -e "Please restart your terminal or run ${BOLD}source ~/.zshrc${NC} to apply changes."
    
    exit 0
}

# Execute main function
main
