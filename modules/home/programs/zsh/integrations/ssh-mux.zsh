#!/usr/bin/env zsh
# shellcheck disable=all

function ssh() {
  local host=$1

  if [[ -n ${WEZTERM_PANE:-} && -z ${SSH_CONNECTION:-} ]] \
    && (( $# == 1 )) && [[ $host != -* && $host != *@* ]]; then
    local pane
    if pane=$(wezterm cli spawn --domain-name "ssh:${host:l}" 2> /dev/null) && [[ -n $pane ]]; then
      wezterm cli activate-pane --pane-id "$pane"
      return 0
    fi
  fi

  command ssh "$@"
}

compdef _ssh ssh
