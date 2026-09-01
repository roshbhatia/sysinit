set -euo pipefail

request="${ORC_PROVIDER_REQUEST:?ORC_PROVIDER_REQUEST is required}"
action="${1:?provider action is required}"
version=$(jq -er '.version' <<< "$request")
requested_action=$(jq -er '.action' <<< "$request")
scope=$(jq -er '.scope' <<< "$request")

if [ "$version" != "orc.provider/v1" ]; then
  printf 'orc-sysinit: unsupported request version: %s\n' "$version" >&2
  exit 2
fi

if [ "$action" != "$requested_action" ]; then
  printf 'orc-sysinit: action mismatch: %s != %s\n' "$action" "$requested_action" >&2
  exit 2
fi

split() {
  local direction
  direction=$(jq -er '.direction' <<< "$request")
  case "$direction" in
    right | left | top | bottom) ;;
    *)
      printf 'orc-sysinit: unsupported split direction: %s\n' "$direction" >&2
      exit 2
      ;;
  esac

  local args=("--$direction" --cwd "$scope")
  if [ -n "${WEZTERM_PANE:-}" ]; then
    args+=(--pane-id "$WEZTERM_PANE")
  fi
  exec wezterm cli --no-auto-start split-pane "${args[@]}" -- "$@"
}

case "$action" in
  attach)
    provider_ref=$(jq -er '.session.providerRef' <<< "$request")
    split zmx attach "$provider_ref"
    ;;
  inspect)
    trace_id=$(jq -er '.session.traceId // .session.nativeId' <<< "$request")
    split traces --session "$trace_id"
    ;;
  changes)
    exec changes -r -root "$scope" -color always
    ;;
  launch)
    managed_id=$(jq -er '.managedId' <<< "$request")
    command=()
    while IFS= read -r -d '' value; do
      command+=("$value")
    done < <(jq -j '.command[] | @text, "\u0000"' <<< "$request")
    if [ "${#command[@]}" -eq 0 ]; then
      printf 'orc-sysinit: launch command is empty\n' >&2
      exit 2
    fi
    exec zmx attach "$managed_id" "${command[@]}"
    ;;
  *)
    printf 'orc-sysinit: unsupported action: %s\n' "$action" >&2
    exit 2
    ;;
esac
