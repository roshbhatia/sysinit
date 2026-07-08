# agent-prompt: actionable permission notification with keystroke relay.
#
# The escalation of agent-notify for permission/approval events: instead of a
# fire-and-forget toast, it shows an `alerter` notification carrying Accept/Deny
# buttons, then a detached waiter relays the human's choice back into the exact
# wezterm pane the agent runs in (Accept -> approve keystroke, Deny -> reject).
# The hook returns immediately; the waiter lives on in the background until the
# human acts or the notification times out.
#
# Usage: agent-prompt <agent> <reason> [focus-exe]
#   <agent>      claude | codex | …   (selects icon/label AND the relay keymap)
#   <reason>     approval | attention | …  (only genuine approvals go actionable)
#   [focus-exe]  agent-focus path, forwarded to the plain-notifier fallback so
#                click-to-focus is preserved when the actionable path is skipped.
#
# Baked in by notify.nix at build time (see the preamble prepended there):
#   RELAY_ENABLED   "1" when sysinit.llm.notifications.actionableRelay is on
#   NOTIFY_EXE      absolute path to agent-notify (the fallback path)
#
# Best-effort by contract: never blocks or fails the agent. No strict mode,
# every external call guarded, always exits 0. When the actionable path does not
# apply — relay disabled, no alerter, non-approval event, or an agent with no
# keymap — it degrades to the exact plain-notifier behavior it replaced.

agent=${1:-agent}
reason=${2:-attention}
focus_exe=${3:-}

input=""
if [ ! -t 0 ]; then
  input=$(cat 2> /dev/null)
fi

# json FILTER -> field value, or empty on any error / missing field.
json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

cwd=$(json '.cwd')
[ -n "$cwd" ] || cwd=$PWD
msg=$(json '.message')

# Refine a generic "attention" (Claude/Gemini Notification) into approval/idle
# from the human string, mirroring agent-notify so the two agree on when an
# event is really a permission prompt.
eff_reason=$reason
if [ "$eff_reason" = "attention" ] && [ -n "$msg" ]; then
  case "$msg" in
    *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) eff_reason="approval" ;;
    *idle* | *[Ww]aiting*) eff_reason="idle" ;;
  esac
fi

# Per-agent approve/reject keystrokes for the relay. Best-effort, tunable: these
# assume each harness's default permission prompt (Claude highlights "Yes", so
# Enter approves and Esc cancels; Codex takes y/n shortcuts). An agent absent
# from this map has no relay and is routed to the plain notifier instead — the
# relay never guesses keys it does not know.
approve_keys=""
reject_keys=""
case "$agent" in
  claude)
    approve_keys=$(printf '\r')
    reject_keys=$(printf '\033')
    ;;
  codex)
    approve_keys="y"
    reject_keys="n"
    ;;
esac

# The fallback: reproduce agent-notify's plain clickable toast with the ORIGINAL
# reason so it runs its own classification. Used whenever the actionable path
# does not apply.
plain_notify() {
  [ -n "$NOTIFY_EXE" ] || return 0
  printf '%s' "$input" | "$NOTIFY_EXE" "$agent" "$reason" "$focus_exe" 2> /dev/null || true
}

pane=${WEZTERM_PANE:-}
alerter=$(command -v alerter 2> /dev/null || true)

# Gates for the actionable path — any miss falls back to click-to-focus only:
#   - relay toggle on (the kill switch)
#   - alerter present (macOS-only, optional)
#   - a real approval event (never nag Accept/Deny for idle/done)
#   - a known relay keymap for this agent
#   - a pane to relay into
if [ "${RELAY_ENABLED:-0}" != "1" ] ||
  [ -z "$alerter" ] ||
  [ "$eff_reason" != "approval" ] ||
  [ -z "$approve_keys" ] ||
  [ -z "$pane" ]; then
  plain_notify
  exit 0
fi

# --- identity: session + repo, for the subtitle/group (shared resolver) ---
agent_identity "$cwd" "$pane"
session=$AI_SESSION
repo=$AI_REPO
if [ -n "$session" ] && [ -n "$repo" ] && [ "$session" != "$repo" ]; then
  context="$session · $repo"
elif [ -n "$session" ]; then
  context="$session"
elif [ -n "$repo" ]; then
  context="$repo"
else
  context=$(basename "$cwd")
fi

# --- agent -> label + icon (same asset set as agent-notify) ---
icons="${XDG_DATA_HOME:-$HOME/.local/share}/agent-notify/icons"
case "$agent" in
  claude) label="Claude Code" ;;
  codex) label="Codex" ;;
  gemini) label="Gemini" ;;
  cursor) label="Cursor" ;;
  aider) label="Aider" ;;
  *) label="$agent" ;;
esac
icon="$icons/$agent.png"
[ -f "$icon" ] || icon="$icons/agent.png"

title="$label · needs your approval"
body=${msg:-needs your approval}
# One slot per agent+context so a repeat prompt replaces the pending one.
group="agent-prompt:$agent:$context"

wz=$(command -v wezterm 2> /dev/null || true)

# Detached waiter: alerter blocks until the human picks (or the timeout fires),
# then we relay the decision into the pane. Backgrounded + disowned with stdio
# detached so the hook returns now and the wait outlives it.
(
  action=$(
    "$alerter" \
      --title "$title" \
      --subtitle "$context" \
      --message "$body" \
      --actions "Accept,Deny" \
      --app-icon "$icon" \
      --content-image "$icon" \
      --sound "Funk" \
      --group "$group" \
      --timeout 300 \
      2> /dev/null
  ) || action=""

  # Relay only on an explicit button. alerter prints "@TIMEOUT"/"@CLOSED"/
  # "@CONTENTCLICKED" (or empty) for the non-decision outcomes — all no-ops.
  keys=""
  case "$action" in
    Accept) keys=$approve_keys ;;
    Deny) keys=$reject_keys ;;
  esac

  if [ -n "$keys" ] && [ -n "$wz" ]; then
    # send-text --no-paste delivers the bytes as real keystrokes (Enter, Esc,
    # y/n) rather than a bracketed paste, so the harness's prompt reacts.
    printf '%s' "$keys" | "$wz" cli send-text --no-paste --pane-id "$pane" 2> /dev/null || true
  fi
) < /dev/null > /dev/null 2>&1 &
disown 2> /dev/null || true

exit 0
