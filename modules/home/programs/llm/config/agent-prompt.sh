# agent-prompt: actionable permission notification with keystroke relay.
#
# The escalation of agent-notify for permission/approval events: instead of a
# fire-and-forget toast, it shows an `alerter` notification carrying Accept/Deny

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
notif_type=$(json '.notification_type')

# The fallback: reproduce agent-notify's plain clickable toast with the ORIGINAL
# reason so it runs its own classification. Used whenever the actionable path
# does not apply. Defined before the classification block below, which calls it.
plain_notify() {
  [ -n "$NOTIFY_EXE" ] || return 0
  printf '%s' "$input" | "$NOTIFY_EXE" "$agent" "$reason" "$focus_exe" 2> /dev/null || true
}

# Classify "attention" using notification_type first, message-text as fallback.
# Mirrors agent-notify's classification exactly so the two scripts always agree.
eff_reason=$reason
if [ "$eff_reason" = "attention" ]; then
  case "$notif_type" in
    permission_prompt | agent_needs_input) eff_reason="approval" ;;
    idle_prompt) eff_reason="idle" ;;
    agent_completed) eff_reason="done" ;;
    auth_success | elicitation_complete | elicitation_response)
      plain_notify
      exit 0
      ;;
    "")
      case "$msg" in
        *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) eff_reason="approval" ;;
        *idle* | *[Ww]aiting* | *[Ii]nput*) eff_reason="idle" ;;
      esac
      ;;
    *)
      plain_notify
      exit 0
      ;;
  esac
fi

# Per-agent approve/reject keystrokes for the relay. Best-effort, tunable: these
# assume each harness's default permission prompt (Claude highlights "Yes", so
# Enter approves and Esc cancels; Codex takes y/n shortcuts). An agent absent
# from this map has no relay and is routed to the plain notifier instead — the
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

pane=${WEZTERM_PANE:-}
alerter=$(command -v alerter 2> /dev/null || true)

# Gates for the actionable path — any miss falls back to click-to-focus only:
#   - alerter present (macOS-only, optional)
#   - a real approval event (never nag Accept/Deny for idle/done)
#   - a known relay keymap for this agent
if [ -z "$alerter" ] ||
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
  opencode) label="OpenCode" ;;
  pi) label="Pi" ;;
  copilot) label="Copilot" ;;
  amp) label="Amp" ;;
  crush) label="Crush" ;;
  goose) label="Goose" ;;
  devin) label="Devin" ;;
  *) label="$agent" ;;
esac
icon="$icons/$agent.png"
[ -f "$icon" ] || icon="$icons/agent.png"

title="$label · needs your approval"
body=${msg:-needs your approval}
# Same slot as agent-notify uses for this pane, so a repeat prompt replaces the
# pending one AND agent-focus can dismiss it. The two scripts previously wrote
# different prefixes, so an approval toast was never dismissed.
group=$(agent_group "$agent" "$context" "$pane")

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
      --sound "Blow" \
      --group "$group" \
      --timeout 300 \
      2> /dev/null
  ) || action=""

  # Relay only on an explicit button. A body click is not a decision, so it
  # routes to agent-focus instead: the human wants to see the prompt, not
  # answer it blind. alerter prints "@TIMEOUT"/"@CLOSED" for the rest.
  keys=""
  case "$action" in
    Accept) keys=$approve_keys ;;
    Deny) keys=$reject_keys ;;
    @CONTENTCLICKED | @ACTIONCLICKED)
      # Both are "the human engaged but did not pick Accept or Deny". Route to
      # the pane so they can answer the prompt in place. agent-notify.sh treats
      # the same pair identically; the two producers must not disagree.
      if [ -n "$focus_exe" ]; then
        "$focus_exe" "$pane" "$session" > /dev/null 2>&1 || true
      fi
      ;;
  esac

  if [ -n "$keys" ] && [ -n "$wz" ]; then
    # send-text --no-paste delivers the bytes as real keystrokes (Enter, Esc,
    # y/n) rather than a bracketed paste, so the harness's prompt reacts.
    printf '%s' "$keys" | "$wz" cli send-text --no-paste --pane-id "$pane" 2> /dev/null || true
  fi
) < /dev/null > /dev/null 2>&1 &
disown 2> /dev/null || true

exit 0
