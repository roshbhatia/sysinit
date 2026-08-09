agent=${1:-agent}
reason=${2:-attention}
focus_exe=${3:-}

input=""
if [ ! -t 0 ]; then
  input=$(cat 2> /dev/null)
fi

json() {
  [ -n "$input" ] || return 0
  printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

cwd=$(json '.cwd')
[ -n "$cwd" ] || cwd=$PWD
msg=$(json '.message')
notif_type=$(json '.notification_type')

plain_notify() {
  [ -n "$NOTIFY_EXE" ] || return 0
  printf '%s' "$input" | "$NOTIFY_EXE" "$agent" "$reason" "$focus_exe" 2> /dev/null || true
}

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

pane=${WEZTERM_PANE:-}
alerter=$(command -v alerter 2> /dev/null || true)

# No `approve_keys` clause. It used to stand here and it was doing two jobs: it
# selected the rich alerter, and it also restricted the rich alerter to claude
# and codex, because those were the only two agents with a keystroke table. The
# table is gone, so the restriction went with it and every agent now gets the
# same notification. The alerter no longer answers a prompt; it tells you an
# agent is waiting and puts you in the pane when you click.
if [ -z "$alerter" ] ||
  [ "$eff_reason" != "approval" ] ||
  [ -z "$pane" ]; then
  plain_notify
  exit 0
fi

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
group=$(agent_group "$agent" "$context" "$pane")

(
  action=$(
    "$alerter" \
      --title "$title" \
      --subtitle "$context" \
      --message "$body" \
      --app-icon "$icon" \
      --content-image "$icon" \
      --sound "Blow" \
      --group "$group" \
      --timeout 300 \
      2> /dev/null
  ) || action=""

  # One arm, and it is the owner clicking. `--actions "Accept,Deny"` is gone
  # from the alerter call above, so `Accept` and `Deny` are no longer reachable
  # actions and their arms went with them. `@ACTIONCLICKED` stays because
  # alerter still reports it for a click on the notification body.
  case "$action" in
    @CONTENTCLICKED | @ACTIONCLICKED)
      if [ -n "$focus_exe" ]; then
        "$focus_exe" "$pane" "$session" > /dev/null 2>&1 || true
      fi
      ;;
  esac
) < /dev/null > /dev/null 2>&1 &
disown 2> /dev/null || true

exit 0
