#!/usr/bin/env zsh
# shellcheck disable=all
env.print() {
  local pattern=${1:-"*"}
  env | grep -E "^$pattern=" | sort | bat --style=numbers,grid
}

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS

unset MAILCHECK
