# agent-focus: notification click handler — raise the wezterm pane an agent runs in.
#
# Invoked by agent-notify's detached waiter when the human clicks an agent-notify
# notification (see agent-notify.sh). Runs in a bare NotificationCenter context
# (no shell rc, minimal env), so it depends only on its own runtimeInputs.
#
# Usage: agent-focus <pane-id> [session]
#   <pane-id>  the WEZTERM_PANE the agent had when it notified (may be empty/stale)
#   [session]  the seshy session / wezterm workspace name — fallback when the pane
#              id no longer resolves (pane closed, agent moved)
#
# Best-effort: try the exact pane, then any pane in the session, then just bring
# wezterm to the front. Always exits 0 — a click should never surface an error.

pane=${1:-}
session=${2:-}

wz=$(command -v wezterm 2> /dev/null || true)
notifier=$(command -v alerter 2> /dev/null || true)

# Dismiss the originating toast immediately so it doesn't linger until its timeout.
# Reconstruct the group from the pane's state file: same agent-notify:$agent:$context
# pattern that agent-notify.sh uses. Best-effort — silent on any failure.
if [ -n "$notifier" ] && [ -n "$pane" ]; then
  state_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$pane.json"
  if [ -f "$state_file" ]; then
    _agent=$(jq -r '.agent // empty' "$state_file" 2>/dev/null || true)
    _session=$(jq -r '.session // empty' "$state_file" 2>/dev/null || true)
    _repo=$(jq -r '.repo // empty' "$state_file" 2>/dev/null || true)
    if [ -n "$_session" ] && [ -n "$_repo" ] && [ "$_session" != "$_repo" ]; then
      _context="$_session · $_repo"
    elif [ -n "$_session" ]; then
      _context="$_session"
    elif [ -n "$_repo" ]; then
      _context="$_repo"
    fi
    if [ -n "$_agent" ] && [ -n "$_context" ]; then
      "$notifier" --remove "agent-notify:$_agent:$_context" > /dev/null 2>&1 || true
    fi
  fi
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
