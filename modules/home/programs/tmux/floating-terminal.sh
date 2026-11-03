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
if [ -n "$parent" ]; then
  tmux -S "$socket" switch-client -c "$client" -t "$parent"
  session=$parent
  floating="_sysinit_float_${session#\$}"
fi

pane=$(tmux -S "$socket" show-option -qv -t "$session" @sysinit_float_pane)
target=$(tmux -S "$socket" display-message -p -t "$session:" '#{pane_id}')
if [ -n "$pane" ] && [ "$(tmux -S "$socket" display-message -p -t "$pane" '#{pane_id}')" = "$pane" ]; then
  owner=$(tmux -S "$socket" display-message -p -t "$pane" '#{session_id}')
  if [ "$owner" = "$session" ]; then
    staging=$(tmux -S "$socket" new-session -d -P -F '#{pane_id}' -s "$floating" -c "$cwd" "$BASH" --noprofile --norc)
    floating_id=$(tmux -S "$socket" display-message -p -t "$staging" '#{session_id}')
    tmux -S "$socket" set-option -t "$floating_id" @sysinit_float_parent "$session"
    exec tmux -S "$socket" join-pane -s "$pane" -t "$staging" \; kill-pane -t "$staging"
  fi
  exec tmux -S "$socket" join-pane -s "$pane" -t "$target" \; \
    break-pane -W -s "$pane" -x 85% -y 80% -X 7% -Y 10%
fi

pane=$(tmux -S "$socket" new-pane -P -F '#{pane_id}' -t "$target" -c "$cwd" -x 85% -y 80% -X 7% -Y 10% \
  -T 'Floating terminal (Ctrl-B f hides)')
tmux -S "$socket" set-option -t "$session" @sysinit_float_pane "$pane"
