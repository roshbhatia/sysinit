# agent-notify: agent-agnostic desktop-notification hook (alerter backend).
#
# Fires one macOS notification (sound + per-agent app icon) when a coding agent
# needs the human: it is waiting for approval, has gone idle, or just finished a
# turn (your move). Wired into each harness's lifecycle hooks; see notify.nix.
#
# Usage: agent-notify <agent> <reason> [focus-exe]
#   <agent>      claude | codex | gemini | cursor | amp   (selects the icon/label)
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
  opencode) label="OpenCode" ;;
  pi) label="Pi" ;;
  copilot) label="Copilot" ;;
  amp) label="Amp" ;;
  crush) label="Crush" ;;
  goose) label="Goose" ;;
  devin) label="Devin" ;;
  *) label="$agent" ;;
esac
# agent.png is the generic glyph, distinct from every harness icon, so an
# unrecognized agent is never rendered as a recognized one.
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
        *) exit 0 ;; # Unclassified — suppress rather than spam
      esac
      ;;
    *) exit 0 ;; # Unknown notification_type — suppress
  esac
fi

# Gate done-notifications on a minimum elapsed time so quick replies don't
# ping. The .start file is written by agent-state when UserPromptSubmit fires
# (reason_src=submit). If the file is absent (Codex, other agents), notify
# unconditionally since we have no timing signal.
if [ "$reason" = "done" ] && [ -n "${WEZTERM_PANE:-}" ]; then
  start_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$WEZTERM_PANE.start"
  if [ -f "$start_file" ]; then
    start=$(cat "$start_file" 2> /dev/null) || start=0
    now=$(date +%s 2> /dev/null) || now=0
    elapsed=$((now - start))
    [ "$elapsed" -lt 60 ] && exit 0
  fi
fi

# Deduplicate idle notifications: only fire once per 5-minute window per agent
# so a stuck or repeatedly idle agent doesn't flood the notification centre.
if [ "$reason" = "idle" ]; then
  notif_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/notif"
  mkdir -p "$notif_dir" 2> /dev/null || true
  # Keyed on the pane, not the agent: two panes running one harness must both
  # notify. Falls back to agent+context when no pane id is available (ssh).
  #
  # The fallback hashes the pair rather than substituting unsafe characters.
  # `tr -c 'A-Za-z0-9._-' '_'` is lossy: "my session" and "my_session" both
  # collapse to "my_session", and the "·" this script uses as the context
  # separator is multi-byte, so it becomes two underscores and collides with a
  # literal "__". Two distinct sessions would then share one dedup file and the
  # second would be wrongly suppressed, which is the defect this key exists to
  # prevent.
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

# --- reason -> wording + sound (sounds are names under /System/Library/Sounds) ---
# `what` is the category for the title; the message body below carries the
# specifics (which tool, what choice) so the human knows WHY before switching.
# Every branch sets a timeout: alerter blocks its (backgrounded) waiter for the
# whole duration, so an unbounded 0 would leak one process per notification.
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

# --- enrich the body from the per-pane state file ---
# A "done" toast that says only "finished its turn" makes the human switch to
# find out what changed. The state file already holds the repository, the
# branch, whether the worktree is dirty, and when the transition happened, so
# the toast can answer that before the switch.
#
# Everything here is best-effort. A missing, unreadable, or partial state file
# degrades to the harness message alone, never to an error.
if [ -n "$pane" ]; then
  state_file="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes/$pane.json"
  if [ -f "$state_file" ]; then
    # Separated by \001, not by tab. Tab is an IFS whitespace character, so bash
    # collapses runs of them and an empty field shifts every later value left:
    # a repo with no branch would read the timestamp as its branch name.
    st=$(jq -rj '[.repo // "", .branch // "", (if .dirty then "dirty" else "" end), (.since // 0 | tostring)] | join("\u0001")' "$state_file" 2> /dev/null) || st=""
    if [ -n "$st" ]; then
      IFS=$(printf '\001') read -r s_repo s_branch s_dirty s_since <<< "$st"

      # repo·branch, with a marker when the worktree has uncommitted changes.
      where=""
      [ -n "$s_repo" ] && where="$s_repo"
      if [ -n "$s_branch" ]; then
        [ -n "$where" ] && where="$where · $s_branch" || where="$s_branch"
      fi
      [ -n "$s_dirty" ] && [ -n "$where" ] && where="$where ✱"

      # Elapsed since the transition, in the same units the statusline uses.
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

      # reason — where — age, skipping any part we could not resolve.
      for part in "$where" "$age"; do
        [ -n "$part" ] && body="$body — $part"
      done
    fi
  fi
fi
# One notification slot per pane so repeats from that pane replace instead of
# stacking, and any handler can rebuild the name from the pane id alone.
# WEZTERM_PANE is not forwarded over ssh and this script still runs without it,
# so a paneless caller falls back to the agent+context pair. Keying an empty
# pane id would collapse every paneless session onto one slot.
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

# alerter blocks until the human acts or the timeout fires, then prints the
# outcome (@CONTENTCLICKED / @ACTIONCLICKED / @CLOSED / @TIMEOUT) on stdout. It
# has no --execute flag, so click-to-focus is a detached waiter we run ourselves:
# background the call and route a content click back to the agent's pane. Same
# shape as agent-prompt's relay. The hook returns now; the waiter outlives it.
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
