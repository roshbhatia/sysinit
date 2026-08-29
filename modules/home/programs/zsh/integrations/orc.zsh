#!/usr/bin/env zsh
# shellcheck disable=all

_orc_prompt_update() {
  local value=""
  if (( $+commands[orc] )); then
    value=$(orc prompt 2> /dev/null)
  fi
  if [[ -n $value ]]; then
    export ORC_PROMPT=$value
  else
    unset ORC_PROMPT
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _orc_prompt_update
_orc_prompt_update
