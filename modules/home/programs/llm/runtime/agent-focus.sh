# agent-focus: notification click handler — raise the wezterm pane an agent runs in.
#
# Invoked by agent-notify's detached waiter when the human clicks an agent-notify
# notification (see agent-notify.sh). Runs in a bare NotificationCenter context

pane=${1:-}
session=${2:-}

wz=$(command -v wezterm 2> /dev/null || true)
notifier=$(command -v alerter 2> /dev/null || true)

# Dismiss the originating toast immediately so it doesn't linger until its timeout.
# The group is `agent:<pane-id>`, which both producers write, so it rebuilds from
# the pane id alone. The previous version read the pane's state file to rebuild an
# agent+context name, which could not match the prefix agent-prompt wrote, so an
if [ -n "$notifier" ] && [ -n "$pane" ]; then
  "$notifier" --remove "$(agent_group "" "" "$pane")" > /dev/null 2>&1 || true
fi

raise_app() {
  # Bring the wezterm window forward even when no specific pane was activated.
  /usr/bin/osascript -e 'tell application "WezTerm" to activate' 2> /dev/null || true
}

# No wezterm CLI — best we can do is foreground the app.
[ -n "$wz" ] || {
  raise_app
  exit 0
}

# 1. Exact pane the agent reported.
if [ -n "$pane" ] && "$wz" cli activate-pane --pane-id "$pane" 2> /dev/null; then
  raise_app
  exit 0
fi

# 2. Pane gone — find another pane in the same session/workspace, preferring the
#    active one, and activate that.
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

# 3. Nothing matched — at least foreground wezterm.
raise_app
exit 0
