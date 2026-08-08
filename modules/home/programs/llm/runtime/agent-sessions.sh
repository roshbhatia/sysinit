state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents"
panes_dir="$state_dir/panes"
selected_file="$state_dir/selected.json"

STALE_AFTER=${AGENT_SESSIONS_STALE_AFTER:-10}

emit_empty() {
  printf '{"selected":null,"selection_state":"absent","sessions":[]}\n'
  exit 0
}

command -v jq > /dev/null 2>&1 || emit_empty

now=$(date +%s)

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
