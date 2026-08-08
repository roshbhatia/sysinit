pane=${1:-}
session=${2:-}

wz=$(command -v wezterm 2> /dev/null || true)
notifier=$(command -v alerter 2> /dev/null || true)

if [ -n "$notifier" ] && [ -n "$pane" ]; then
  "$notifier" --remove "$(agent_group "" "" "$pane")" > /dev/null 2>&1 || true
fi

raise_app() {
  /usr/bin/osascript -e 'tell application "WezTerm" to activate' 2> /dev/null || true
}

[ -n "$wz" ] || {
  raise_app
  exit 0
}

if [ -n "$pane" ] && "$wz" cli activate-pane --pane-id "$pane" 2> /dev/null; then
  raise_app
  exit 0
fi

if [ -n "$session" ]; then
  alt=$("$wz" cli list --format json 2> /dev/null |
    jq -r --arg w "$session" \
      '[.[] | select(.workspace == $w)] | (map(select(.is_active)) + .) | .[0].pane_id // empty' \
      2> /dev/null |
    head -1)
  if [ -n "$alt" ] && "$wz" cli activate-pane --pane-id "$alt" 2> /dev/null; then
    raise_app
    exit 0
  fi
fi

raise_app
exit 0
