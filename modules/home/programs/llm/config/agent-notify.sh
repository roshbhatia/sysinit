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
notif_timeout=60
case "$reason" in
  approval)
    what="needs your approval"
    sound="Blow"      # distinctive whoosh — action required, but not jarring
    notif_timeout=600 # the human must act, but bound the waiter at 10 min
    ;;
  idle)
    what="is waiting for you"
    sound="Pop"       # brief, minimal — gentle nudge
    notif_timeout=120 # auto-dismiss after 2 min; stale idle is noise
    ;;
  done)
    what="finished its turn"
    sound="Ping"     # clean single tone — satisfying completion signal
    notif_timeout=30 # auto-dismiss after 30 s; done is informational
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

# Name the review path in the body, so the human knows what changed before
# switching. Degrades to the harness message alone if the state file is unusable.
if [ -n "$pane" ]; then
  state_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$pane.json"
  if [ -f "$state_file" ]; then
    # \001, not tab: tab is IFS whitespace, so bash collapses runs of it and an
    # empty field shifts every later value left
    st=$(jq -rj '[.repo // "", .branch // "", (if .dirty then "dirty" else "" end), (.since // 0 | tostring)] | join("\u0001")' "$state_file" 2> /dev/null) || st=""
    if [ -n "$st" ]; then
      IFS=$(printf '\001') read -r s_repo s_branch s_dirty s_since <<< "$st"

      where=""
      [ -n "$s_repo" ] && where="$s_repo"
      if [ -n "$s_branch" ]; then
        [ -n "$where" ] && where="$where · $s_branch" || where="$s_branch"
      fi
      [ -n "$s_dirty" ] && [ -n "$where" ] && where="$where ✱"

      age=""
      case "$s_since" in
        '' | *[!0-9]*) : ;;
        0) : ;;
        *)
          now=$(date +%s 2> /dev/null) || now=0
          secs=$((now - s_since))
          if [ "$secs" -ge 0 ] 2> /dev/null; then
            if [ "$secs" -lt 60 ]; then
              age="${secs}s"
            elif [ "$secs" -lt 3600 ]; then
              age="$((secs / 60))m"
            else
              age="$((secs / 3600))h"
            fi
          fi
          ;;
      esac

      for part in "$where" "$age"; do
        [ -n "$part" ] && body="$body — $part"
      done
    fi
  fi
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
