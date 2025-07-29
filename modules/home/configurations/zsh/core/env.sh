#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/env.sh (begin)
env.print() {
  local pattern=${1:-"*"}
  env | grep -E "^$pattern=" | sort | bat --style=numbers,grid
}

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
export LS_COLORS=$(vivid generate $VIVID_THEME)
export EZA_COLORS=$LS_COLORS
# modules/darwin/home/zsh/core/env.sh (end)

