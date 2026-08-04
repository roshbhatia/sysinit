# The session rollup, for a status bar. Prints JSON on stdout and always exits 0.
#
# Why this exists: `ui.lua` already computes per-session agent state, but only
# inside WezTerm. sketchybar and waybar cannot call into WezTerm's Lua, so the
# rollup has to be readable from outside. This reads the same two sources ui.lua
# does: the per-pane state bus under $XDG_STATE_HOME/agents/panes/ and `sy list`.
#
# Exit code is deliberately always 0. A bar polls this on a timer, and a non-zero
# exit for the ordinary idle case (no WezTerm, no sessions) would make every bar
# render an error state as the steady state.
#
# Usage: agent-sessions [--json]
#
# Selection and the heartbeat: only WezTerm knows which workspace is active, so it
# writes {selected, heartbeat} to $XDG_STATE_HOME/agents/selected.json on its
# update-status tick. This compares that heartbeat against now and reports
# selection_state as one of:
#   fresh   WezTerm is ticking; `selected` is current
#   stale   the file exists but the heartbeat is old, so WezTerm is gone or wedged
#   absent  no file at all, so WezTerm has never run in this state dir
# A bar dims a stale selection rather than blanking it, and never shows a stale
# selection as current. Without the heartbeat those two cases are the same file.

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents"
panes_dir="$state_dir/panes"
selected_file="$state_dir/selected.json"

# A tick is 1s in ui.lua's update-status. Three missed ticks plus slack: long
# enough that a busy mux is not called dead, short enough that a closed WezTerm
# stops being reported as current within a bar refresh or two.
STALE_AFTER=${AGENT_SESSIONS_STALE_AFTER:-10}

emit_empty() {
  printf '{"selected":null,"selection_state":"absent","sessions":[]}\n'
  exit 0
}

command -v jq > /dev/null 2>&1 || emit_empty

now=$(date +%s)

# --- selection ----------------------------------------------------------------
selected=null
selection_state=absent
if [ -f "$selected_file" ]; then
  sel=$(jq -r '.selected // ""' "$selected_file" 2> /dev/null)
  beat=$(jq -r '.heartbeat // 0' "$selected_file" 2> /dev/null)
  case "$beat" in
    '' | *[!0-9]*) beat=0 ;;
  esac
  if [ -n "$sel" ]; then
    selected=$(jq -cn --arg s "$sel" '$s')
    age=$((now - beat))
    if [ "$beat" -gt 0 ] && [ "$age" -le "$STALE_AFTER" ]; then
      selection_state=fresh
    else
      selection_state=stale
    fi
  fi
fi

# --- live panes ---------------------------------------------------------------
# Intersect state files with panes the mux still lists, the same rule ui.lua and
# agent-review use. A state file outlives its pane, so without this a finished
# session reports as busy forever. When the mux cannot be reached the intersection
# is unknown, and the honest answer is to trust the files rather than to drop
# every session.
live=""
have_live=0
if command -v wezterm > /dev/null 2>&1; then
  live=$(wezterm cli list --format json 2> /dev/null | jq -r '.[].pane_id' 2> /dev/null | tr '\n' ' ')
  [ -n "$live" ] && have_live=1
fi

pane_is_live() {
  [ "$have_live" -eq 0 ] && return 0
  case " $live " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- roll up per session ------------------------------------------------------
# Worst-wins, matching the statusline's ordering: waiting (you must act) beats
# done (your move) beats working. A session's status is its worst pane's.
rank_of() {
  case "$1" in
    waiting) echo 3 ;;
    done) echo 2 ;;
    working) echo 1 ;;
    *) echo 0 ;;
  esac
}

rollup=$(
  if [ -d "$panes_dir" ]; then
    for f in "$panes_dir"/*.json; do
      [ -f "$f" ] || continue
      pane=$(jq -r '.pane // ""' "$f" 2> /dev/null)
      [ -n "$pane" ] || continue
      pane_is_live "$pane" || continue
      sess=$(jq -r '.session // ""' "$f" 2> /dev/null)
      [ -n "$sess" ] || sess="default"
      status=$(jq -r '.status // ""' "$f" 2> /dev/null)
      repo=$(jq -r '.repo // ""' "$f" 2> /dev/null)
      since=$(jq -r '.since // 0' "$f" 2> /dev/null)
      printf '%s\t%s\t%s\t%s\t%s\n' "$sess" "$(rank_of "$status")" "$status" "$repo" "$since"
    done
  fi
)

# `sy list` names sessions that hold no agent pane, so an idle session is still
# offered. Column 1 is the name; the header row is dropped by requiring a
# following column count, matching how ui.lua reads it.
known=$(
  if command -v sy > /dev/null 2>&1; then
    sy list 2> /dev/null | awk 'NR > 1 && NF > 0 { print $1 }'
  fi
)

printf '%s' "$rollup" | jq -R -s --arg sel "$selected_file" --argjson selected "$selected" \
  --arg selstate "$selection_state" --arg known "$known" '
  def rows: split("\n") | map(select(length > 0) | split("\t"));
  ( rows
    | group_by(.[0])
    | map({
        name: .[0][0],
        status: (max_by(.[1] | tonumber) | .[2]),
        rank: (max_by(.[1] | tonumber) | .[1] | tonumber),
        repo: ([.[] | .[3] | select(length > 0)] | first // ""),
        panes: length,
        blocked: ([.[] | select((.[1] | tonumber) >= 1)] | length),
        since: ([.[] | .[4] | tonumber | select(. > 0)] | min // null),
      })
  ) as $active
  | ( $known | split("\n") | map(select(length > 0)) ) as $names
  | ( $names - ($active | map(.name)) | map({ name: ., status: null, rank: 0, repo: "", panes: 0, blocked: 0, since: null }) ) as $idle
  | { selected: $selected,
      selection_state: $selstate,
      sessions: (($active + $idle) | sort_by(-.rank, .name)) }
' 2> /dev/null || emit_empty
