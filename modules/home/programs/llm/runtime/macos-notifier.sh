notification_binary=${NOTIFICATION_EXE:?}
args=()
image=""
interactive=true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --title | --subtitle | --message | --group | --sound)
      [ "$#" -ge 2 ] || exit 2
      # NSUserDefaults otherwise interprets leading brackets as property lists.
      args+=("-${1#--}" "\\$2")
      shift 2
      ;;
    --timeout)
      [ "$#" -ge 2 ] || exit 2
      args+=(-timeout "$2")
      shift 2
      ;;
    --app-icon | --content-image)
      [ "$#" -ge 2 ] || exit 2
      image=$2
      shift 2
      ;;
    --remove)
      [ "$#" -ge 2 ] || exit 2
      args+=(-remove "\\$2")
      interactive=false
      shift 2
      ;;
    --help) exec "$notification_binary" -help ;;
    --diagnose) exec "$notification_binary" -diagnose ;;
    *)
      printf 'sysinit-notification: unsupported option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done
if [ "$interactive" = true ]; then
  if [ -n "${AGENT_NOTIFY_FOCUS_EXE:-}" ]; then
    quote_argument() {
      printf "'%s'" "${1//\'/\'\\\'\'}"
    }
    focus_command="$(quote_argument "$AGENT_NOTIFY_FOCUS_EXE") $(quote_argument "${AGENT_NOTIFY_PANE:-}") $(quote_argument "${AGENT_NOTIFY_SESSION:-}")"
    if [ -n "${WEZTERM_UNIX_SOCKET:-}" ]; then
      focus_command="WEZTERM_UNIX_SOCKET=$(quote_argument "$WEZTERM_UNIX_SOCKET") $focus_command"
    fi
    args+=(-execute "\\$focus_command")
  else
    args+=(-action 'Open session')
  fi
  [ -z "$image" ] || args+=(-contentImage "\\$image")
fi
notify_status=0
outcome=$("$notification_binary" "${args[@]}") || notify_status=$?
case "$outcome" in
  'Open session') printf '%s\n' '@ACTIONCLICKED' ;;
  *)
    printf '%s\n' "$outcome"
    exit "$notify_status"
    ;;
esac
