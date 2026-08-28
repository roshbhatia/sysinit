#!/usr/bin/env zsh
# shellcheck disable=all

_orca_prompt_update() {
  local value=""
  if (( $+commands[orca] )); then
    value=$(orca prompt 2> /dev/null)
  fi
  if [[ -n $value ]]; then
    export ORCA_PROMPT=$value
  else
    unset ORCA_PROMPT
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _orca_prompt_update
_orca_prompt_update
