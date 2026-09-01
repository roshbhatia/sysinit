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

emit_declined() {
  jq -n \
    --arg reason "$1" \
    '{version: "orc.provider/v1", status: "declined", reason: $reason}'
}

emit_binding() {
  local kind status ref label
  kind=$1
  status=$2
  ref=$3
  label=$4
  jq -n \
    --arg kind "$kind" \
    --arg status "$status" \
    --arg ref "$ref" \
    --arg label "$label" \
    '{
      version: "orc.provider/v1",
      binding: {
        kind: $kind,
        status: $status,
        ref: (if $ref == "" then null else $ref end),
        label: $label
      }
    }'
}

emit_description() {
  jq -n \
    --arg title "$1" \
    --arg goal "$2" \
    '{version: "orc.provider/v1", description: {title: $title, goal: $goal}}'
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

current_session_matches() {
  local native_id candidate
  native_id=$(jq -r '.session.nativeId // empty' <<< "$request")
  if [ -z "$native_id" ]; then
    return 1
  fi
  for candidate in \
    "${ORC_NATIVE_SESSION_ID:-}" \
    "${CODEX_THREAD_ID:-}" \
    "${CODEX_SESSION_ID:-}" \
    "${CLAUDE_CODE_SESSION_ID:-}" \
    "${CLAUDE_SESSION_ID:-}" \
    "${OPENCODE_SESSION_ID:-}"; do
    if [ -n "$candidate" ] && [ "$candidate" = "$native_id" ]; then
      return 0
    fi
  done
  return 1
}

agent_registry=${ORC_AGENT_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/sysinit/agents.json}

case "$provider_kind:$capability" in
  changes:changes.inspect)
    emit_plan "$scope" '{}' "$(command -v changes)" -r -root "$scope" -color always
    ;;
  harness:session.bind)
    harness=$(jq -r '.session.harness // empty' <<< "$request")
    if [ ! -s "$agent_registry" ] || ! jq -e --arg harness "$harness" '.agents[] | select(.name == $harness)' "$agent_registry" > /dev/null; then
      emit_declined "harness is absent from the agent registry"
    elif current_session_matches; then
      emit_binding "harness" "active" "$(jq -r '.session.nativeId' <<< "$request")" "$harness session"
    else
      emit_binding "harness" "available" "$(jq -r '.session.nativeId' <<< "$request")" "$harness resume"
    fi
    ;;
  harness:session.attach)
    harness=$(jq -r '.session.harness // empty' <<< "$request")
    agent=$(jq -ce --arg harness "$harness" '.agents[] | select(.name == $harness)' "$agent_registry" 2> /dev/null || true)
    if [ -z "$agent" ] || [ "$(jq -r '.launch.resumeArgs // [] | length' <<< "$agent")" -eq 0 ]; then
      emit_declined "harness does not advertise resume support"
      exit 0
    fi
    harness_command=$(jq -r '.command' <<< "$agent")
    executable=$(command -v "$harness_command" || true)
    if [ -z "$executable" ]; then
      emit_declined "harness command is unavailable"
      exit 0
    fi
    resume_command=("$executable")
    while IFS= read -r -d '' value; do
      resume_command+=("$value")
    done < <(jq -j '.launch.resumeArgs | .[] | @text, "\u0000"' <<< "$agent")
    resume_command+=("$(jq -er '.session.nativeId' <<< "$request")")
    model=$(jq -r '.session.model // empty' <<< "$request")
    model_flag=$(jq -r '.launch.modelFlag // empty' <<< "$agent")
    if [ -n "$model" ] && [ -n "$model_flag" ]; then
      resume_command+=("$model_flag" "$model")
    fi
    emit_plan "$scope" '{}' "${resume_command[@]}"
    ;;
  traces:session.bind)
    trace_id=$(jq -r '.session.traceId // .session.nativeId // empty' <<< "$request")
    if [ -n "$trace_id" ]; then
      emit_binding "activity" "active" "$trace_id" "Traces activity"
    else
      emit_declined "session has no trace identity"
    fi
    ;;
  traces:session.describe)
    trace_id=$(jq -r '.session.traceId // .session.nativeId // empty' <<< "$request")
    prompt=$(
      traces --json -session "$trace_id" 2> /dev/null |
        jq -n -r 'first(inputs | select(((.attrs.prompt? // "") | type) == "string" and ((.attrs.prompt? // "") | length) > 0) | .attrs.prompt) // empty'
    ) || true
    if [ -z "$prompt" ]; then
      emit_declined "Traces has no user prompt for this session"
    else
      title=${prompt%%$'\n'*}
      emit_description "${title:0:72}" "$prompt"
    fi
    ;;
  traces:session.inspect)
    trace_id=$(jq -er '.session.traceId // .session.nativeId | select(type == "string" and length > 0)' <<< "$request")
    emit_plan "$scope" '{}' "$(command -v traces)" --once -color always -session "$trace_id"
    ;;
  wezterm:session.bind)
    if current_session_matches && [ -n "${WEZTERM_PANE:-}" ]; then
      emit_binding "display" "active" "$WEZTERM_PANE" "WezTerm pane $WEZTERM_PANE"
    else
      emit_binding "display" "available" "" "WezTerm split"
    fi
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
  zmx:session.bind)
    if current_session_matches && [ -n "${ZMX_SESSION:-}" ]; then
      zmx_session=${ZMX_SESSION#"${ZMX_SESSION_PREFIX:-}"}
      emit_binding "persistence" "active" "$zmx_session" "Zmx session $zmx_session"
    else
      emit_binding "persistence" "available" "" "Zmx on next launch"
    fi
    ;;
  zmx:session.persist)
    provider_ref=$(jq -r '
      first(
        .session.providers[]?
        | select(.provider == "zmx" and .kind == "persistence" and .status == "active")
        | .ref
      ) // .session.providerRef // empty
    ' <<< "$request")
    if [ -n "$provider_ref" ]; then
      emit_plan "$scope" '{}' "$(command -v zmx)" attach "$provider_ref"
    else
      read_command '.plan.command'
      managed_id=$(jq -r '.session.id' <<< "$request" | sed 's/[^[:alnum:]_.-]/-/g')
      prior_environment=$(jq -ce '.plan.environment // {} | objects' <<< "$request")
      emit_plan "$scope" "$prior_environment" "$(command -v zmx)" attach "$managed_id" "${command[@]}"
    fi
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
