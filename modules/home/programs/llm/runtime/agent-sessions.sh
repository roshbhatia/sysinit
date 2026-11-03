state_dir=$(sysinit_path agents) || state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents"
panes_dir=$(sysinit_path agentPanes) || panes_dir="$state_dir/panes"
selected_file="$state_dir/selected.json"
cache_file="$state_dir/sessions.json"
lock_dir="$state_dir/sessions.lock"

STALE_AFTER=${AGENT_SESSIONS_STALE_AFTER:-10}
PROBE_TIMEOUT=${AGENT_SESSIONS_PROBE_TIMEOUT:-2}
LOCK_STALE_AFTER=${AGENT_SESSIONS_LOCK_STALE_AFTER:-30}

emit_empty() {
  printf '{"selected":null,"selection_state":"absent","discovery_state":"unavailable","sessions":[]}\n'
  exit 0
}

emit_cached() {
  if [ -s "$cache_file" ] && jq -e '
    select(type == "object" and (.sessions | type) == "array")
    | .selection_state = "stale" | .discovery_state = "unavailable"
  ' "$cache_file" 2> /dev/null; then
    exit 0
  fi
  emit_empty
}

command -v jq > /dev/null 2>&1 || emit_empty

mkdir -p "$state_dir" 2> /dev/null || true

now=$(date +%s)

if [ -d "$lock_dir" ]; then
  born=$(cat "$lock_dir/born" 2> /dev/null)
  case "$born" in
    '' | *[!0-9]*) born=0 ;;
  esac
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

available=0
if live=$(timeout "$PROBE_TIMEOUT" wezterm cli --no-auto-start list --format json 2> /dev/null) &&
  printf '%s' "$live" | jq -e 'type == "array" and all(.[]; type == "object" and has("pane_id"))' > /dev/null 2>&1; then
  available=1
else
  live='[]'
fi
if tmux_live=$(timeout "$PROBE_TIMEOUT" tmux list-panes -a -F '#{pane_id}	#{session_name}	#{pane_active}' 2> /dev/null); then
  available=1
  tmux_live=$(printf '%s\n' "$tmux_live" | jq -Rs 'split("\n") | map(select(length > 0) | split("\t") | {pane_id: .[0], workspace: .[1], is_active: (.[2] == "1")})')
  live=$(jq -cn --argjson native "$live" --argjson tmux "$tmux_live" '$native + $tmux')
fi
if [ "$available" = 0 ]; then
  emit_cached
fi
known=$(timeout "$PROBE_TIMEOUT" sy list --names 2> /dev/null) || known=""
shopt -s nullglob
pane_files=("$panes_dir"/*.json)
records='[]'
if [ "${#pane_files[@]}" -gt 0 ]; then
  records=$(
    for pane_file in "${pane_files[@]}"; do
      printf '%s\0' "$(< "$pane_file")"
    done | jq -Rs 'split("\u0000") | map(fromjson? | select(type == "object"))'
  ) || emit_cached
fi
if [ -n "${tmux_live:-}" ] && inferred=$(timeout "$PROBE_TIMEOUT" @tmuxStatusCommand@/bin/tmux-agent-status "$panes_dir" "$state_dir/tmux-inference.json" 2> /dev/null); then
  records=$(jq -cn --argjson records "$records" --argjson inferred "$inferred" '$records | map(select((.pane | tostring | startswith("%")) | not)) | . + $inferred') || emit_cached
fi
out=$(printf '%s' "$records" | jq --argjson live "$live" --argjson selected "$selected" \
  --arg selstate "$selection_state" --arg known "$known" -f @agentSessionsReducer@) || emit_cached
[ -n "$out" ] || emit_cached
printf '%s\n' "$out" > "$cache_file.tmp" 2> /dev/null &&
  mv -f "$cache_file.tmp" "$cache_file" 2> /dev/null
printf '%s\n' "$out"
