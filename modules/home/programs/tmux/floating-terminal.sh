#!/usr/bin/env bash
set -euo pipefail

case "${1:-}:$#" in
  toggle:5 | redirect:5 | cleanup:3) ;;
  *)
    printf 'usage: tmux-floating-terminal toggle|redirect <socket> <session> <client> <cwd> | cleanup <socket> <session>\n' >&2
    exit 2
    ;;
esac

action=$1
socket=$2
session=$3
floating="_sysinit_float_${session#\$}"

if [ "$action" = cleanup ]; then
  if tmux -S "$socket" has-session -t "=$floating" 2> /dev/null; then
    floating_id=$(tmux -S "$socket" display-message -p -t "=$floating:" '#{session_id}')
    parent=$(tmux -S "$socket" show-option -qv -t "$floating_id" @sysinit_float_parent)
    if [ "$parent" = "$session" ]; then
      tmux -S "$socket" kill-session -t "$floating_id"
    fi
  fi
  exit 0
fi

client=$4
cwd=$5
parent=$(tmux -S "$socket" show-option -qv -t "$session" @sysinit_float_parent)
if [ "$action" = redirect ] && [ -n "$parent" ]; then
  floating=$(tmux -S "$socket" display-message -p -t "$session:" '#{session_name}')
  tmux -S "$socket" switch-client -c "$client" -t "$parent"
elif [ -n "$parent" ]; then
  exec tmux -S "$socket" detach-client -t "$client"
fi

if ! tmux -S "$socket" has-session -t "=$floating" 2> /dev/null; then
  floating_id=$(tmux -S "$socket" new-session -d -P -F '#{session_id}' -s "$floating" -c "$cwd")
  tmux -S "$socket" set-option -t "$floating_id" @sysinit_float_parent "$session"
fi

printf -v attach '%q ' env -u TMUX TERM=tmux-256color TERM_PROGRAM=tmux tmux -S "$socket" attach-session -t "=$floating"
tmux -S "$socket" display-popup -C -c "$client"
exec tmux -S "$socket" display-popup -E -c "$client" -d "$cwd" -w 85% -h 80% \
  -T 'Floating terminal (Ctrl-B f hides)' "$attach"
