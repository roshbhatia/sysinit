#!/usr/bin/env bash

agent_busy_panes() {
  local session="$1"
  local live="$2"
  local state_dir
  # sysinit:documented-default
  state_dir=$(sysinit_path agentPanes) || state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes"
  # Reads the pane records.
  local busy=0 f pane st ag sess

  [ -d "$state_dir" ] || return 0

  for f in "$state_dir"/*.json; do
    [ -f "$f" ] || continue
    pane=$(basename "$f" .json)
    # The liveness rule from SCHEMA.md: pane existence.
    printf '%s\n' "$live" | grep -qx "$pane" || continue

    read -r st ag sess <<< "$(jq -r '[.status // "", .agent // "", .session // ""] | @tsv' "$f" 2> /dev/null)"
    [ "$sess" = "$session" ] || continue
    case "$st" in
      working | waiting | done)
        busy=1
        printf '  pane %-19s %-28s %s is %s\n' "$pane" "" "$ag" "$st"
        ;;
    esac
  done

  [ "$busy" -eq 0 ] || return 1
  return 0
}
