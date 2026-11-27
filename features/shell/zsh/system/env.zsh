#!/usr/bin/env zsh
# shellcheck disable=all
env.print() {
  local pattern=${1:-"*"}
  env | grep -E "^$pattern=" | sort | bat --style=numbers,grid
}

export GIT_OPTIONAL_LOCKS=0

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
