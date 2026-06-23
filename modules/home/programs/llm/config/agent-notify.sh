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

# --- session identity: which seshy session AND which repo ---
# The agent runs inside a wezterm pane whose `workspace` is the seshy session name
# (WEZTERM_PANE is inherited into the hook). That is the reliable session signal —
# more so than cwd, which may have wandered out of the session tree. Fall back to
# the cwd-under-seshy-root parse, then to the workspace name, then to nothing.
pane=${WEZTERM_PANE:-}
wz=$(command -v wezterm 2> /dev/null || true)
workspace=""
if [ -n "$pane" ] && [ -n "$wz" ]; then
  workspace=$("$wz" cli list --format json 2> /dev/null |
    jq -r --arg p "$pane" '.[] | select((.pane_id | tostring) == $p) | .workspace' 2> /dev/null |
    head -1)
fi

seshy_root="$HOME/.local/state/seshy/sessions"
session=""
case "$cwd/" in
  "$seshy_root"/*)
    rest=${cwd#"$seshy_root"/}
    session=${rest%%/*}
    ;;
esac
# wezterm's unnamed default workspace is not a session — ignore it.
if [ -z "$session" ] && [ -n "$workspace" ] && [ "$workspace" != "default" ]; then
  session=$workspace
fi

repo=""
repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null)
[ -n "$repo_root" ] && repo=$(basename "$repo_root")

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

# Generic "attention" payloads (Claude/Gemini Notification) carry a human string
# that tells us whether it is really a permission prompt or an idle nudge.
if [ "$reason" = "attention" ] && [ -n "$msg" ]; then
  case "$msg" in
    *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) reason="approval" ;;
    *idle* | *[Ww]aiting*) reason="idle" ;;
  esac
fi

# --- reason -> wording + sound (sounds are names under /System/Library/Sounds) ---
# `what` is the category for the title; the message body below carries the
# specifics (which tool, what choice) so the human knows WHY before switching.
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
[ -n "$exec_cmd" ] && args+=(-execute "$exec_cmd")

"$notifier" "${args[@]}" > /dev/null 2>&1 || true

exit 0
