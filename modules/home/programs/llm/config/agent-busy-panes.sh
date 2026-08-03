#!/usr/bin/env bash
# Which panes of a session still hold a non-idle agent state.
#
# Sourced by `agent-review.sh` and by the `agent-review-readiness` flake check, so
# the gate and the assertion run the same code.
#
# Usage: agent_busy_panes <session> <live-pane-ids>
#
# `live-pane-ids` is a newline-separated list, and it is a PARAMETER rather than
# something this function reads: `agent-review` is a writeShellApplication whose
# runtimeInputs are prepended to PATH, so a fixture cannot stub `wezterm`. Passing
# the list in is what makes the intersection testable at all.
#
# Prints one report line per busy pane and returns 1 when any pane is busy, 0 when
# none is. A state file records that a pane HELD a state, not that it still
# exists, so a file whose pane is absent from the live list is ignored: assuming
# liveness would turn one crashed session into a permanent blocker.

agent_busy_panes() {
  local session="$1"
  local live="$2"
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes"
  local busy=0 f pane st ag sess

  [ -d "$state_dir" ] || return 0

  for f in "$state_dir"/*.json; do
    [ -f "$f" ] || continue
    pane=$(basename "$f" .json)
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
