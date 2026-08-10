# sysinit:documented-default
state_dir=$(sysinit_path agents) || state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents"
# Pane records.
panes_dir=$(sysinit_path agentPanes) || panes_dir="$state_dir/panes"
selected_file="$state_dir/selected.json"
cache_file="$state_dir/sessions.json"
lock_dir="$state_dir/sessions.lock"

STALE_AFTER=${AGENT_SESSIONS_STALE_AFTER:-10}
# Every external call is bounded: a status line runs this on a timer, so an unbounded
# call stacks processes rather than merely running slow.
PROBE_TIMEOUT=${AGENT_SESSIONS_PROBE_TIMEOUT:-2}
LOCK_STALE_AFTER=${AGENT_SESSIONS_LOCK_STALE_AFTER:-30}

emit_empty() {
  printf '{"selected":null,"selection_state":"absent","sessions":[]}\n'
  exit 0
}

# Answer from the last good run rather than computing a second one.
emit_cached() {
  if [ -s "$cache_file" ]; then
    cat "$cache_file"
    exit 0
  fi
  emit_empty
}

command -v jq > /dev/null 2>&1 || emit_empty

mkdir -p "$state_dir" 2> /dev/null || true

# One instance at a time.
now=$(date +%s)

if [ -d "$lock_dir" ]; then
  born=$(cat "$lock_dir/born" 2> /dev/null)
  case "$born" in
    '' | *[!0-9]*) born=0 ;;
  esac
  # A lock with no readable birth time is stale, or a kill mid-stamp wedges the timer.
  if [ "$born" -eq 0 ] || [ "$((now - born))" -ge "$LOCK_STALE_AFTER" ]; then
    rm -rf "$lock_dir" 2> /dev/null || true
  fi
fi
mkdir "$lock_dir" 2> /dev/null || emit_cached
printf '%s\n' "$now" > "$lock_dir/born" 2> /dev/null || true
trap 'rm -rf "$lock_dir" 2> /dev/null || true' EXIT INT TERM

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

live=""
have_live=0
pane_ws=""
active_pane=""
if command -v wezterm > /dev/null 2>&1; then
  # Bounded: an unresponsive mux makes `wezterm cli list` block with no timeout of its
  pane_ws=$(timeout "$PROBE_TIMEOUT" wezterm cli list --format json 2> /dev/null |
    jq -r '.[] | "\(.pane_id) \(.workspace // "") \(.is_active)"' 2> /dev/null)
  live=$(printf '%s\n' "$pane_ws" | awk 'NF { print $1 }' | tr '\n' ' ')
  [ -n "$live" ] && have_live=1
fi

# The liveness rule from SCHEMA.md: a record counts while its pane exists.
pane_is_live() {
  [ "$have_live" -eq 0 ] && return 0
  case " $live " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Which workspace owns this pane, resolved live rather than recorded: pane ids are
workspace_of() {
  [ -n "$pane_ws" ] || return 0
  printf '%s\n' "$pane_ws" | awk -v p="$1" '$1 == p { print $2; exit }'
}

# The record session of a pane, or empty.
session_of_pane() {
  [ -n "$1" ] || return 0
  [ -f "$panes_dir/$1.json" ] || return 0
  jq -r '.session // ""' "$panes_dir/$1.json" 2> /dev/null
}

# Reconcile `selected` into the SESSION namespace.
if [ -n "$pane_ws" ]; then
  active_pane=$(printf '%s\n' "$pane_ws" | awk '$3 == "true" { print $1; exit }')
fi
if [ "$selected" != null ] && [ -n "$active_pane" ]; then
  sel_session=$(session_of_pane "$active_pane")
  [ -n "$sel_session" ] && selected=$(jq -cn --arg s "$sel_session" '$s')
fi

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
      # Record session, then live workspace, then "default", treating a workspace
      # literally named "default" as no workspace at all.
      [ -n "$sess" ] || sess=$(workspace_of "$pane")
      [ -n "$sess" ] || sess="default"
      status=$(jq -r '.status // ""' "$f" 2> /dev/null)
      repo=$(jq -r '.repo // ""' "$f" 2> /dev/null)
      since=$(jq -r '.since // 0' "$f" 2> /dev/null)
      printf '%s\t%s\t%s\t%s\t%s\n' "$sess" "$(rank_of "$status")" "$status" "$repo" "$since"
    done
  fi
)

known=$(
  if command -v sy > /dev/null 2>&1; then
    timeout "$PROBE_TIMEOUT" sy list 2> /dev/null | awk 'NR > 1 && NF > 0 { print $1 }'
  fi
)

out=$(printf '%s' "$rollup" | jq -R -s --arg sel "$selected_file" --argjson selected "$selected" \
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
' 2> /dev/null) || emit_cached

[ -n "$out" ] || emit_cached

# Cached by rename, so a reader never sees a half-written document.
printf '%s\n' "$out" > "$cache_file.tmp" 2> /dev/null &&
  mv -f "$cache_file.tmp" "$cache_file" 2> /dev/null
printf '%s\n' "$out"
