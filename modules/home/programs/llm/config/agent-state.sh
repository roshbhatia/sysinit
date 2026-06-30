# agent-state: agent-agnostic per-pane lifecycle-state emitter.
#
# Publishes the calling agent's current state to its WezTerm pane as an OSC 1337
# SetUserVar named `agent_state`, so the statusline and seshy session switcher
# can show WHICH session is blocked and WHY without switching into each pane.
# The companion `agent-notify` still fires the desktop toast; this only writes
# the user-var. WezTerm discards user-vars when the pane closes, so there is no
# stale state to prune.
#
# Usage: agent-state <agent> <status> [reason-source]
#   <agent>         claude | codex | gemini | cursor | aider   (free-form label)
#   <status>        working | waiting | done | idle
#   [reason-source] how to derive the human reason string:
#                     tool     -> build from .tool_name + .tool_input (PreToolUse)
#                     message  -> use the event's .message            (Notification)
#                     <other>  -> the literal text itself             ("your move")
# The hook event JSON is read from stdin; every field is optional.
#
# Best-effort by contract: it must never block or fail the agent. No strict
# mode, every external call is guarded, and it always exits 0. With no
# controlling tty (no WezTerm pane) it writes nothing.

agent=${1:-agent}
status=${2:-working}
reason_src=${3:-}

# The user-var only matters inside a WezTerm pane; bail quietly otherwise.
[ -n "${WEZTERM_PANE:-}" ] || exit 0

input=""
if [ ! -t 0 ]; then
  input=$(cat 2> /dev/null)
fi

# json FILTER -> field value, or empty string on any error / missing field.
json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

# --- resolve the human reason ---
case "$reason_src" in
  tool)
    tool=$(json '.tool_name')
    # The most telling field varies by tool; take the first that exists.
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

# Squash to a single safe line: drop the `|` delimiter, collapse all whitespace
# (incl. newlines) to single spaces, trim, and bound the length so a label is
# always short. tr/awk are guarded; on any failure we fall back to the status.
reason=$(
  printf '%s' "$reason" |
    tr '|\n\r\t' '    ' |
    awk '{ $1 = $1; print }' 2> /dev/null
) || reason="$status"
[ -n "$reason" ] || reason="$status"
# Bound to ~60 chars; the surfaces truncate further to fit.
reason=${reason:0:60}

since=$(date +%s 2> /dev/null) || since=0

# value = base64("<status>|<reason>|<since>|<agent>"). WezTerm requires the
# SetUserVar value to be base64; it decodes it before delivering to Lua.
payload="$status|$reason|$since|$agent"
b64=$(printf '%s' "$payload" | base64 2> /dev/null | tr -d '\n') || exit 0
[ -n "$b64" ] || exit 0

# OSC 1337 SetUserVar to the controlling tty. /dev/tty (not stdout, which the
# harness captures) is the pane WezTerm is reading. If there is no tty this is a
# silent no-op.
printf '\033]1337;SetUserVar=agent_state=%s\007' "$b64" > /dev/tty 2> /dev/null || true

exit 0
