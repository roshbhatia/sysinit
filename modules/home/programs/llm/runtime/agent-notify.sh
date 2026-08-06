# Desktop notification when an agent needs the human (alerter backend).
#
# Usage: agent-notify <agent> <reason> [focus-exe]
#   <reason>  approval | idle | done | attention

agent=${1:-agent}
reason=${2:-attention}
focus_exe=${3:-}

# alerter is macOS-only; on anything else this is a silent no-op.
notifier=$(command -v alerter 2> /dev/null) || exit 0

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

# The pane's wezterm workspace is the seshy session name, which is more reliable
# than cwd as cwd may have wandered out of the session tree.
pane=${WEZTERM_PANE:-}
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

# --- agent -> label + icon ---
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

# notification_type first, message text as fallback. Unclassified is suppressed
# rather than shown, so auth and elicitation bookkeeping never surface.
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
        *) exit 0 ;; # Unclassified — suppress rather than spam
      esac
      ;;
    *) exit 0 ;; # Unknown notification_type — suppress
  esac
fi

# Quick replies should not ping. No .start file means no timing signal, so
# notify unconditionally.
if [ "$reason" = "done" ] && [ -n "${WEZTERM_PANE:-}" ]; then
  start_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$WEZTERM_PANE.start"
  if [ -f "$start_file" ]; then
    start=$(cat "$start_file" 2> /dev/null) || start=0
    now=$(date +%s 2> /dev/null) || now=0
    elapsed=$((now - start))
    [ "$elapsed" -lt 60 ] && exit 0
  fi
fi

if [ "$reason" = "idle" ]; then
  notif_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/notif"
  mkdir -p "$notif_dir" 2> /dev/null || true
  # Keyed on the pane so two panes of one harness both notify. The paneless
  # fallback hashes: `tr -c` is lossy, collapsing "my session" and "my_session"
  # onto one key.
  if [ -n "$pane" ]; then
    dedup_key="${pane}_idle"
  else
    ctx_hash=$(printf '%s' "$agent|$context" | cksum 2> /dev/null | cut -d' ' -f1) || ctx_hash=""
    [ -n "$ctx_hash" ] || ctx_hash=0
    dedup_key="ctx${ctx_hash}_idle"
  fi
  dedup_file="$notif_dir/$dedup_key"
  if [ -f "$dedup_file" ]; then
    last=$(cat "$dedup_file" 2> /dev/null) || last=0
    now=$(date +%s 2> /dev/null) || now=0
    elapsed=$((now - last))
    [ "$elapsed" -lt 300 ] && exit 0
  fi
  printf '%s' "$(date +%s 2> /dev/null || printf '0')" > "$dedup_file" 2> /dev/null || true
fi

# Sounds are names under /System/Library/Sounds. Every branch sets a timeout:
# alerter blocks its backgrounded waiter, so 0 would leak a process per toast.
#
# The timeout is also the click-to-focus window. Clicking a toast runs
# agent-focus on the originating pane (see the waiter at the end of this file),
# and alerter stops listening the moment it times out. So a short timeout is not
# purely cosmetic: it trades away the one interaction these toasts offer.
#
# Hence per-reason, not one number. `done` is informational and nothing is
# waiting on it, so 5s is right. `approval` means the agent is BLOCKED on a
# permission prompt: dismissing that in 5s leaves it stuck with no signal left on
# screen, which is the failure this notifier exists to prevent. `idle` sits
# between, and its whole point is to be clicked.
#
# Each is overridable, so tuning does not need a Nix edit and a switch:
#   AGENT_NOTIFY_TIMEOUT_DONE / _IDLE / _APPROVAL / _DEFAULT
notif_timeout=${AGENT_NOTIFY_TIMEOUT_DEFAULT:-30}
case "$reason" in
  approval)
    what="needs your approval"
    sound="Blow" # distinctive whoosh — action required, but not jarring
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_APPROVAL:-600}
    ;;
  idle)
    what="is waiting for you"
    sound="Pop" # brief, minimal — gentle nudge
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_IDLE:-60}
    ;;
  done)
    what="finished its turn"
    sound="Ping" # clean single tone — satisfying completion signal
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_DONE:-5}
    ;;
  *)
    what="needs your attention"
    sound="Pop"
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_DEFAULT:-30}
    ;;
esac

title="$label · $what"
# Prefer the harness's own message ("needs your permission to use Bash", the
# specific prompt, …) — it names what the human must act on. Fall back to the
# category when the event carried nothing.
body=${msg:-$what}

# Name the review path in the body, so the human knows what changed before
# switching. Degrades to the harness message alone if the state file is unusable.
# The suffix is composed by a sourced helper so the flake check can assert the
# same code the toast uses, rather than a copy of it.
if [ -n "$pane" ]; then
  body="$body$(agent_review_suffix "$pane")"
fi
group=$(agent_group "$agent" "$context" "$pane")

args=(
  --title "$title"
  --subtitle "$context"
  --message "$body"
  --app-icon "$icon"
  --sound "$sound"
  --group "$group"
  --timeout "$notif_timeout"
)

# alerter blocks until the human acts and has no --execute flag, so
# click-to-focus is a backgrounded waiter that outlives this hook.
(
  outcome=$("$notifier" "${args[@]}" 2> /dev/null) || outcome=""
  if [ -n "$focus_exe" ]; then
    case "$outcome" in
      @CONTENTCLICKED | @ACTIONCLICKED)
        "$focus_exe" "$pane" "$session" > /dev/null 2>&1 || true
        ;;
    esac
  fi
) < /dev/null > /dev/null 2>&1 &
disown 2> /dev/null || true

exit 0
