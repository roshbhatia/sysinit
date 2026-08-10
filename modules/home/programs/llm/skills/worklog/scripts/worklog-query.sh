#!/usr/bin/env bash
set -euo pipefail

# Read one path out of the paths manifest. The layout has one owner,
# sysinit:documented-default
sysinit_state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
sysinit_manifest="${SYSINIT_PATHS_MANIFEST:-$sysinit_state_root/sysinit/paths.json}"

sysinit_path() {
  [ -s "$sysinit_manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  sp_value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$sysinit_manifest" 2> /dev/null) || return 1
  [ -n "$sp_value" ] || return 1
  printf '%s\n' "$sp_value"
}

WORKLOG_FILE="${CLAUDE_WORKLOG_FILE:-$(sysinit_path agentWorklog)}"
: "${WORKLOG_FILE:?the paths manifest has no agentWorklog entry and CLAUDE_WORKLOG_FILE is unset}"

usage() {
  cat >&2 << 'EOF'
usage: worklog-query.sh <command> [args]

commands:
  list    [--since TS] [--until TS] [--repo NAME]  normalized entries, one JSON object per line, newest first
  pending [--since TS] [--until TS] [--repo NAME]  list, filtered to entries whose summary is null
  apply   <summaries.json>                         fill null summaries from {"<session_id>": "<summary>", ...}
                                                   via temp-file + atomic mv; existing summaries are never overwritten

TS compares lexicographically against .ts (ISO-8601, e.g. 2026-06-09).
Reads $CLAUDE_WORKLOG_FILE, default the agentWorklog entry of the paths
manifest. Malformed
lines are skipped by list/pending and preserved verbatim by apply.
EOF
  exit 2
}

readonly NORMALIZE='
  def normalize:
    if .v == 2 then .
    elif has("repos") then
      .v = 1
      | .repos = [
          .repos[]
          | if has("commits") and ((.commits | type) == "number")
            then .commits_ahead = .commits | del(.commits)
            else .
            end
        ]
    else
      .v = 0
      | .kind = (.kind // "repo")
      | .repos = (
          if .repo then [{ name: .repo, branch: (.branch // ""), head: (.head // "") }] else [] end
        )
    end;
'

run_list() {
  local pending_only="$1"
  shift
  local since="" until_ts="" repo=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --since)
        since="${2:?--since needs a timestamp}"
        shift 2
        ;;
      --until)
        until_ts="${2:?--until needs a timestamp}"
        shift 2
        ;;
      --repo)
        repo="${2:?--repo needs a name}"
        shift 2
        ;;
      *) usage ;;
    esac
  done

  [[ -f ${WORKLOG_FILE} ]] || {
    echo "ERROR: ${WORKLOG_FILE} not found" >&2
    exit 1
  }

  jq -cnR \
    --arg since "${since}" \
    --arg until "${until_ts}" \
    --arg repo "${repo}" \
    --argjson pending "${pending_only}" \
    "${NORMALIZE}"'
    [inputs | fromjson? | select(type == "object") | normalize]
    | group_by(.session_id)
    | map(max_by(.ts))
    | map(select(($since == "") or (.ts >= $since)))
    | map(select(($until == "") or (.ts <= $until)))
    | map(select(($repo == "") or (.session_name == $repo) or (any(.repos[]?; .name == $repo))))
    | map(select(($pending | not) or (.summary == null)))
    | sort_by(.ts)
    | reverse
    | .[]
  ' "${WORKLOG_FILE}"
}

run_apply() {
  local sumfile="${1:?apply needs a summaries.json path}"

  jq -e 'type == "object" and (to_entries | all(.value | type == "string"))' "${sumfile}" > /dev/null ||
    {
      echo "ERROR: ${sumfile} must be a JSON object of session_id -> summary strings" >&2
      exit 1
    }

  [[ -f ${WORKLOG_FILE} ]] || {
    echo "ERROR: ${WORKLOG_FILE} not found" >&2
    exit 1
  }

  local tmp
  tmp="$(mktemp "${WORKLOG_FILE}.XXXXXX")"
  trap 'rm -f "${tmp}"' EXIT

  jq -rR --slurpfile s "${sumfile}" '
    . as $raw
    | (fromjson? // null) as $j
    | if $j == null then $raw
      elif ($j.summary == null) and (($s[0][$j.session_id]? // null) != null)
      then ($j | .summary = $s[0][$j.session_id]) | tojson
      else $raw
      end
  ' "${WORKLOG_FILE}" > "${tmp}"

  mv "${tmp}" "${WORKLOG_FILE}"
  trap - EXIT
}

main() {
  [[ $# -ge 1 ]] || usage
  local cmd="$1"
  shift
  case "${cmd}" in
    list) run_list false "$@" ;;
    pending) run_list true "$@" ;;
    apply) run_apply "$@" ;;
    *) usage ;;
  esac
}

main "$@"
