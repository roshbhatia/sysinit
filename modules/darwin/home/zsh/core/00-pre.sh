#!/usr/bin/env zsh
# shellcheck disable=all
typeset -U path cdpath fpath manpath
setopt EXTENDED_GLOB
[[ -f "${HOME}/.zshsecrets" ]] && source "${HOME}/.zshsecrets"
[[ -f "${HOME}/.zshwork" ]] && source "${HOME}/.zshwork"

# ZSH plugin check - this helps diagnose missing plugins
function check_zsh_plugin() {
  local plugin_name=$1
  local plugin_file=$2
  for dir in "${fpath[@]}"; do
    if [[ -f "$dir/$plugin_file" ]]; then
      return 0 # Found
    fi
  done
  echo "WARNING: $plugin_name plugin not found in fpath"
  return 1 # Not found
}

# Check for critical plugins
check_zsh_plugin "fzf-tab" "fzf-tab.plugin.zsh"
check_zsh_plugin "zsh-autosuggestions" "zsh-autosuggestions.plugin.zsh"
check_zsh_plugin "fast-syntax-highlighting" "fast-syntax-highlighting.plugin.zsh"
 
unset MAILCHECK
stty stop undef