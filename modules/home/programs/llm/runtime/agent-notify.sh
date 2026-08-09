agent=${1:-agent}
reason=${2:-attention}
focus_exe=${3:-}

# The one fallback in this file, reached only when the paths manifest is
# absent. Both state paths below derive from it, so the layout is written
# here once rather than once per branch.
# sysinit:documented-default
an_agents="${XDG_STATE_HOME:-$HOME/.local/state}/agents"

notifier=$(command -v alerter 2> /dev/null) || exit 0

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

icons="${XDG_DATA_HOME:-$HOME/.local/share}/agent-notify/icons"
label=$(agent_label "$agent")
icon="$icons/$agent.png"
[ -f "$icon" ] || icon="$icons/agent.png"

if [ "$reason" = "attention" ]; then
  case "$notif_type" in
    permission_prompt | agent_needs_input) reason="approval" ;;
    idle_prompt) reason="idle" ;;
    agent_completed) reason="done" ;;
    auth_success | elicitation_complete | elicitation_response) exit 0 ;;
    "")
      case "$msg" in
        *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*) reason="approval" ;;
        *idle* | *[Ww]aiting* | *[Ii]nput*) reason="idle" ;;
        *) exit 0 ;; # Unclassified — suppress rather than spam
      esac
      ;;
    *) exit 0 ;; # Unknown notification_type — suppress
  esac
fi

if [ "$reason" = "done" ] && [ -n "${WEZTERM_PANE:-}" ]; then
  an_panes=$(sysinit_path agentPanes) || an_panes="$an_agents/panes"
  start_file="$an_panes/$WEZTERM_PANE.start"
  if [ -f "$start_file" ]; then
    start=$(cat "$start_file" 2> /dev/null) || start=0
    now=$(date +%s 2> /dev/null) || now=0
    elapsed=$((now - start))
    [ "$elapsed" -lt 60 ] && exit 0
  fi
fi

if [ "$reason" = "idle" ]; then
  notif_dir=$(sysinit_path agentNotif) || notif_dir="$an_agents/notif"
  mkdir -p "$notif_dir" 2> /dev/null || true
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

notif_timeout=${AGENT_NOTIFY_TIMEOUT_DEFAULT:-5}
case "$reason" in
  approval)
    what="needs your approval"
    sound="Blow" # distinctive whoosh — action required, but not jarring
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_APPROVAL:-5}
    ;;
  idle)
    what="is waiting for you"
    sound="Pop" # brief, minimal — gentle nudge
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_IDLE:-5}
    ;;
  done)
    what="finished its turn"
    sound="Ping" # clean single tone — satisfying completion signal
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_DONE:-5}
    ;;
  *)
    what="needs your attention"
    sound="Pop"
    notif_timeout=${AGENT_NOTIFY_TIMEOUT_DEFAULT:-5}
    ;;
esac

title="$label · $what"
body=${msg:-$what}

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
