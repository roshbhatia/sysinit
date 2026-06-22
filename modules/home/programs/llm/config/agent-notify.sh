# agent-notify: agent-agnostic terminal-notifier hook.
#
# Fires one macOS notification (sound + per-agent app icon) when a coding agent
# needs the human: it is waiting for approval, has gone idle, or just finished a
# turn (your move). Wired into each harness's lifecycle hooks; see notify.nix.
#
# Usage: agent-notify <agent> <reason>
#   <agent>   claude | codex | gemini | cursor | aider   (selects the icon/label)
#   <reason>  approval | idle | done | attention         (selects sound/wording)
# The hook event JSON is read from stdin; every field is treated as optional so
# the script also works when invoked by hand or by a harness that sends nothing.
#
# Best-effort by contract: it must never block or fail the agent. No strict
# mode, every external call is guarded, and it always exits 0.

agent=${1:-agent}
reason=${2:-attention}

# terminal-notifier is macOS-only; on anything else this is a silent no-op.
notifier=$(command -v terminal-notifier 2>/dev/null) || exit 0

input=""
if [ ! -t 0 ]; then
  input=$(cat 2>/dev/null)
fi

# json FILTER -> field value, or empty string on any error / missing field.
json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

cwd=$(json '.cwd')
[ -n "$cwd" ] || cwd=$PWD
msg=$(json '.message')

# --- seshy session context (mirrors statusline.sh / worklog.sh detection) ---
seshy_root="$HOME/.local/state/seshy/sessions"
context=""
case "$cwd/" in
"$seshy_root"/*)
  rest=${cwd#"$seshy_root"/}
  session=${rest%%/*}
  [ -n "$session" ] && context="seshy: $session"
  ;;
esac
if [ -z "$context" ]; then
  repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$repo" ]; then
    context="repo: $(basename "$repo")"
  else
    context="dir: $(basename "$cwd")"
  fi
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

# Generic "attention" payloads (Claude/Gemini Notification) carry a human string
# that tells us whether it is really a permission prompt or an idle nudge.
if [ "$reason" = "attention" ] && [ -n "$msg" ]; then
  case "$msg" in
  *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) reason="approval" ;;
  *idle* | *[Ww]aiting*) reason="idle" ;;
  esac
fi

# --- reason -> wording + sound (sounds are names under /System/Library/Sounds) ---
case "$reason" in
approval)
  what="needs your approval"
  sound="Funk"
  ;;
idle)
  what="is waiting for you"
  sound="Tink"
  ;;
done)
  what="finished its turn"
  sound="Hero"
  ;;
*)
  what="needs your attention"
  sound="Glass"
  ;;
esac

title="$label · $what"
body=${msg:-$what}
# One notification slot per agent+context so repeats replace instead of stacking.
group="agent-notify:$agent:$context"

"$notifier" \
  -title "$title" \
  -subtitle "$context" \
  -message "$body" \
  -appIcon "$icon" \
  -sound "$sound" \
  -group "$group" \
  >/dev/null 2>&1 || true

exit 0
