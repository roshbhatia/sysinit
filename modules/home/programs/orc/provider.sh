set -euo pipefail

provider_kind=${ORC_PROVIDER_KIND:?ORC_PROVIDER_KIND is required}
request=$(cat)
version=$(jq -er '.version' <<< "$request")
capability=$(jq -er '.capability' <<< "$request")
scope=$(jq -er '.scope' <<< "$request")

if [ "$version" != "orc.provider/v1" ]; then
  printf 'orc-provider-%s: unsupported request version: %s\n' "$provider_kind" "$version" >&2
  exit 2
fi

emit_plan() {
  local cwd environment command_json
  cwd=$1
  environment=$2
  shift 2
  if [ "$#" -eq 0 ]; then
    printf 'orc-provider-%s: command plan is empty\n' "$provider_kind" >&2
    exit 2
  fi
  command_json=$(printf '%s\0' "$@" | jq -Rs 'split("\u0000")[:-1]')
  jq -n \
    --arg cwd "$cwd" \
    --argjson command "$command_json" \
    --argjson environment "$environment" \
    '{version: "orc.provider/v1", command: $command, cwd: $cwd, environment: $environment}'
}

read_command() {
  command=()
  while IFS= read -r -d '' value; do
    command+=("$value")
  done < <(jq -j "$1 | .[] | @text, \"\\u0000\"" <<< "$request")
  if [ "${#command[@]}" -eq 0 ]; then
    printf 'orc-provider-%s: input command is empty\n' "$provider_kind" >&2
    exit 2
  fi
}

case "$provider_kind:$capability" in
  changes:changes.inspect)
    emit_plan "$scope" '{}' "$(command -v changes)" -r -root "$scope" -color always
    ;;
  traces:session.inspect)
    trace_id=$(jq -er '.session.traceId // .session.nativeId | select(type == "string" and length > 0)' <<< "$request")
    emit_plan "$scope" '{}' "$(command -v traces)" --session "$trace_id"
    ;;
  wezterm:terminal.open)
    direction=$(jq -er '.direction' <<< "$request")
    case "$direction" in
      right | left | top | bottom) ;;
      *)
        printf 'orc-provider-wezterm: unsupported split direction: %s\n' "$direction" >&2
        exit 2
        ;;
    esac
    prior_cwd=$(jq -er '.plan.cwd // .scope' <<< "$request")
    prior_environment=$(jq -ce '.plan.environment // {} | objects' <<< "$request")
    read_command '.plan.command'
    split_command=("$(command -v wezterm)" cli --no-auto-start split-pane "--$direction" --cwd "$prior_cwd")
    if [ -n "${WEZTERM_PANE:-}" ]; then
      split_command+=(--pane-id "$WEZTERM_PANE")
    fi
    split_command+=(-- "${command[@]}")
    emit_plan "$scope" "$prior_environment" "${split_command[@]}"
    ;;
  zmx:session.attach)
    provider_ref=$(jq -er '.session.providerRef | select(type == "string" and length > 0)' <<< "$request")
    emit_plan "$scope" '{}' "$(command -v zmx)" attach "$provider_ref"
    ;;
  zmx:session.launch)
    managed_id=$(jq -er '.managedId | select(type == "string" and length > 0)' <<< "$request")
    read_command '.command'
    emit_plan "$scope" '{}' "$(command -v zmx)" attach "$managed_id" "${command[@]}"
    ;;
  *)
    printf 'orc-provider-%s: unsupported capability: %s\n' "$provider_kind" "$capability" >&2
    exit 2
    ;;
esac
