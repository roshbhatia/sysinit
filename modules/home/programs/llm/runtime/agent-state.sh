agent=${1:-agent}
status=${2:-working}
reason_src=${3:-}

[ -n "${WEZTERM_PANE:-}" ] || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes"
state_file="$state_dir/$WEZTERM_PANE.json"

if [ "$status" = "exit" ]; then
  rm -f "$state_file" "$state_dir/$WEZTERM_PANE.start" 2> /dev/null || true
  exit 0
fi

input=""
if [ ! -t 0 ]; then
  input=$(cat 2> /dev/null)
fi

json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

since=$(date +%s 2> /dev/null) || since=0

case "$reason_src" in
  submit)
    reason="thinking"
    if mkdir -p "$state_dir" 2> /dev/null; then
      printf '%s' "$since" > "$state_dir/$WEZTERM_PANE.start" 2> /dev/null || true
    fi
    ;;
  tool)
    tool=$(json '.tool_name')
    detail=$(json '.tool_input.command // .tool_input.file_path // .tool_input.path // .tool_input.description // .tool_input.pattern')
    if [ -n "$tool" ] && [ -n "$detail" ]; then
      reason="$tool: $detail"
    elif [ -n "$tool" ]; then
      reason="$tool"
    else
      reason="$status"
    fi
    ;;
  message)
    reason=$(json '.message')
    [ -n "$reason" ] || reason="$status"
    ;;
  "")
    reason="$status"
    ;;
  *)
    reason="$reason_src"
    ;;
esac

reason=$(
  printf '%s' "$reason" |
    tr '|\n\r\t' '    ' |
    awk '{ $1 = $1; print }' 2> /dev/null
) || reason="$status"
[ -n "$reason" ] || reason="$status"
reason=${reason:0:60}

payload="$status|$reason|$since|$agent"
b64=$(printf '%s' "$payload" | base64 2> /dev/null | tr -d '\n') || exit 0
[ -n "$b64" ] || exit 0

printf '\033]1337;SetUserVar=agent_state=%s\007' "$b64" > /dev/tty 2> /dev/null || true

if mkdir -p "$state_dir" 2> /dev/null; then
  agent_identity "$PWD" "$WEZTERM_PANE"

  case "$WEZTERM_PANE" in
    '' | *[!0-9]*) pane_json="\"$WEZTERM_PANE\"" ;;
    *) pane_json="$WEZTERM_PANE" ;;
  esac
  case "$since" in
    '' | *[!0-9]*) since_json=0 ;;
    *) since_json="$since" ;;
  esac

  tmp_file="$state_file.$$.tmp"
  if jq -cn \
    --argjson pane "$pane_json" \
    --arg session "$AI_SESSION" \
    --arg repo "$AI_REPO" \
    --arg branch "$AI_BRANCH" \
    --argjson dirty "$AI_DIRTY" \
    --arg worktree "$AI_WORKTREE" \
    --arg agent "$agent" \
    --arg status "$status" \
    --arg reason "$reason" \
    --argjson since "$since_json" \
    '{pane:$pane,session:$session,repo:$repo,branch:$branch,dirty:$dirty,worktree:$worktree,agent:$agent,status:$status,reason:$reason,since:$since}' \
    > "$tmp_file" 2> /dev/null; then
    mv -f "$tmp_file" "$state_file" 2> /dev/null || rm -f "$tmp_file" 2> /dev/null || true
  else
    rm -f "$tmp_file" 2> /dev/null || true
  fi
fi

exit 0
