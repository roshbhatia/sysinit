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

# 1 is a type this repo never routes, so fall back to a plain notification.
# 2 is an unclassified message, which still carries the original reason on.
eff_reason=$(agent_classify "$reason" "$notif_type" "$msg")
case $? in
  1)
    plain_notify
    exit 0
    ;;
esac

pane=${WEZTERM_PANE:-}
alerter=$(command -v alerter 2> /dev/null || true)

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
label=$(agent_label "$agent")
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
