#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

#                888             888   d8b888         
#                888             888   Y8P888         
#                888             888      888         
# 88888888.d8888b 88888b. 888  888888888888888.d8888b  
#    d88P 88K     888 "88b888  888888   88888888K      
#   d88P  "Y8888b.888  888888  888888   888888"Y8888b. 
#  d88P        X88888  888Y88b 888Y88b. 888888     X88 
# 88888888 88888P'888  888 "Y88888 "Y888888888 88888P'

ZSH_UTILS_DIR="$HOME/.config/zsh/extras"

function zshutils_help() {
  echo "                888             888   d8b888         "
  echo "                888             888   Y8P888         "
  echo "                888             888      888         "
  echo " 88888888.d8888b 88888b. 888  888888888888888.d8888b  "
  echo "    d88P 88K     888 \"88b888  888888   88888888K      "
  echo "   d88P  \"Y8888b.888  888888  888888   888888\"Y8888b. "
  echo "  d88P        X88888  888Y88b 888Y88b. 888888     X88 "
  echo " 88888888 88888P'888  888 \"Y88888 \"Y888888888 88888P' "
  echo
  echo "ZSH Utilities Library"
  echo "====================="
  echo
  echo "Contains various utility functions and sources utility scripts."
  echo
  echo "Available Commands:"
  echo "  mkcd DIR         Create directory and change into it"
  echo "  zshutils_help    Show this help message"
  echo
  echo "Sourced scripts:"
  echo "  kfzf.sh         Kubernetes resource fuzzy finder"
  echo "  kfwd.sh         Kubernetes port forwarding utility"
  echo "  kellog.sh       Kubernetes logs viewer with stern"
  echo "  crepo.sh        Git repository navigator"
}

# Basic functions
function mkcd() {
  mkdir -p "$1" && cd "$1";
}

# Source all utility scripts
if [[ -d "$ZSH_UTILS_DIR" ]]; then
  for util_script in "$ZSH_UTILS_DIR"/*.sh; do
    if [[ -f "$util_script" ]]; then
      source "$util_script"
    fi
  done
else
  echo "ZSH utilities directory not found: $ZSH_UTILS_DIR"
fi