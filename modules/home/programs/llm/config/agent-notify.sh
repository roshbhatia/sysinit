# agent-notify: agent-agnostic terminal-notifier hook.
#
# Fires one macOS notification (sound + per-agent app icon) when a coding agent
# needs the human: it is waiting for approval, has gone idle, or just finished a
# turn (your move). Wired into each harness's lifecycle hooks; see notify.nix.
#
# Usage: agent-notify <agent> <reason> [focus-exe]
#   <agent>      claude | codex | gemini | cursor | aider   (selects the icon/label)
#   <reason>     approval | idle | done | attention         (selects sound/wording)
#   [focus-exe]  path to agent-focus; when set, the notification is clickable and
#                routes back to the exact wezterm pane this agent runs in.
# The hook event JSON is read from stdin; every field is treated as optional so
# the script also works when invoked by hand or by a harness that sends nothing.
#
# Best-effort by contract: it must never block or fail the agent. No strict
# mode, every external call is guarded, and it always exits 0.

agent=${1:-agent}
reason=${2:-attention}
focus_exe=${3:-}

# terminal-notifier is macOS-only; on anything else this is a silent no-op.
notifier=$(command -v terminal-notifier 2> /dev/null) || exit 0

input=""
if [ ! -t 0 ]; then
  input=$(cat 2> /dev/null)
fi

# json FILTER -> field value, or empty string on any error / missing field.
json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

cwd=$(json '.cwd')
[ -n "$cwd" ] || cwd=$PWD
msg=$(json '.message')
notif_type=$(json '.notification_type')

# --- session identity: which seshy session AND which repo ---
# The agent runs inside a wezterm pane whose `workspace` is the seshy session name
# (WEZTERM_PANE is inherited into the hook). That is the reliable session signal —
# more so than cwd, which may have wandered out of the session tree. The shared
# resolver (agent-identity.sh, concatenated in at build time) does the
# workspace lookup, seshy-cwd fallback, and git derivation once, so this script
# and agent-state agree on the answer.
pane=${WEZTERM_PANE:-}
agent_identity "$cwd" "$pane"
session=$AI_SESSION
repo=$AI_REPO

# context names both axes when they differ ("session · repo"), else whichever we
# have, else the bare directory.
if [ -n "$session" ] && [ -n "$repo" ] && [ "$session" != "$repo" ]; then
  context="$session · $repo"
elif [ -n "$session" ]; then
  context="$session"
elif [ -n "$repo" ]; then
  context="$repo"
else
  context=$(basename "$cwd")
fi

# --- agent -> label + icon ---
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

# Classify "attention" events using notification_type first (precise), then
# falling back to message-text parsing. Suppress non-actionable types entirely
# so auth confirmations and elicitation bookkeeping never surface as toasts.
if [ "$reason" = "attention" ]; then
  case "$notif_type" in
    permission_prompt | agent_needs_input) reason="approval" ;;
    idle_prompt) reason="idle" ;;
    agent_completed) reason="done" ;;
    auth_success | elicitation_complete | elicitation_response) exit 0 ;;
    "")
      # No notification_type (older Claude / other harnesses): parse message.
      case "$msg" in
        *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) reason="approval" ;;
        *idle* | *[Ww]aiting* | *[Ii]nput*) reason="idle" ;;
        *) exit 0 ;;  # Unclassified — suppress rather than spam
      esac
      ;;
    *) exit 0 ;;  # Unknown notification_type — suppress
  esac
fi

# Gate done-notifications on a minimum elapsed time so quick replies don't
# ping. The .start file is written by agent-state when UserPromptSubmit fires
# (reason_src=submit). If the file is absent (Codex, other agents), notify
# unconditionally since we have no timing signal.
if [ "$reason" = "done" ] && [ -n "${WEZTERM_PANE:-}" ]; then
  start_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$WEZTERM_PANE.start"
  if [ -f "$start_file" ]; then
    start=$(cat "$start_file" 2>/dev/null) || start=0
    now=$(date +%s 2>/dev/null) || now=0
    elapsed=$((now - start))
    [ "$elapsed" -lt 60 ] && exit 0
  fi
fi

# Deduplicate idle notifications: only fire once per 5-minute window per agent
# so a stuck or repeatedly idle agent doesn't flood the notification centre.
if [ "$reason" = "idle" ]; then
  notif_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/notif"
  mkdir -p "$notif_dir" 2>/dev/null || true
  dedup_file="$notif_dir/${agent}_idle"
  if [ -f "$dedup_file" ]; then
    last=$(cat "$dedup_file" 2>/dev/null) || last=0
    now=$(date +%s 2>/dev/null) || now=0
    elapsed=$((now - last))
    [ "$elapsed" -lt 300 ] && exit 0
  fi
  printf '%s' "$(date +%s 2>/dev/null || printf '0')" > "$dedup_file" 2>/dev/null || true
fi

# --- reason -> wording + sound (sounds are names under /System/Library/Sounds) ---
# `what` is the category for the title; the message body below carries the
# specifics (which tool, what choice) so the human knows WHY before switching.
notif_timeout=""
case "$reason" in
  approval)
    what="needs your approval"
    sound="Blow"      # distinctive whoosh — action required, but not jarring
    # approval: no auto-dismiss; the human must act
    ;;
  idle)
    what="is waiting for you"
    sound="Pop"       # brief, minimal — gentle nudge
    notif_timeout=120 # auto-dismiss after 2 min; stale idle is noise
    ;;
  done)
    what="finished its turn"
    sound="Ping"      # clean single tone — satisfying completion signal
    notif_timeout=30  # auto-dismiss after 30 s; done is informational
    ;;
  *)
    what="needs your attention"
    sound="Pop"
    notif_timeout=60
    ;;
esac

title="$label · $what"
# Prefer the harness's own message ("needs your permission to use Bash", the
# specific prompt, …) — it names what the human must act on. Fall back to the
# category when the event carried nothing.
body=${msg:-$what}
# One notification slot per agent+context so repeats replace instead of stacking.
group="agent-notify:$agent:$context"

# Clickable focus: route the click back to this agent's wezterm pane. -execute
# runs via /bin/sh, so quote the args. Pass the session as a fallback key for
# when the pane id has since gone stale.
exec_cmd=""
if [ -n "$focus_exe" ]; then
  exec_cmd=$(printf '%s %q %q' "$focus_exe" "$pane" "$session")
fi

args=(
  -title "$title"
  -subtitle "$context"
  -message "$body"
  -appIcon "$icon"
  -sound "$sound"
  -group "$group"
)
[ -n "$notif_timeout" ] && args+=(-timeout "$notif_timeout")
[ -n "$exec_cmd" ] && args+=(-execute "$exec_cmd")

"$notifier" "${args[@]}" > /dev/null 2>&1 || true

exit 0
