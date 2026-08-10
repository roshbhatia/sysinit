#!/usr/bin/env zsh
# shellcheck disable=all

# A bare `ssh <host>` inside the wezterm GUI opens the host's mux domain instead
# of a plain session, so the remote side keeps running when the tab goes away.
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
