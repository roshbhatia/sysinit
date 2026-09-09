#!/usr/bin/env bash
set -euo pipefail

# A provider/v1 source for roster that lists the seshy sessions on every remote
# host tether knows, one group per host. It is the adapter that replaces
# seshy-remote-list.sh and tether-refresh.sh once the wezterm lua reads roster's
# catalog; until then all three run side by side.
#
# usage: roster-provider-remote-seshy <sources.json>
# The file is rendered by sources.nix: {hosts: [...], attach: [...]}. `attach`
# is the inner argv a session is entered with, `zmx attach` by default; the
# session name is appended.
#
# roster runs this from the GUI's refresh timer and kills it at the manifest
# timeout, so nothing here may block: every ssh carries ConnectTimeout and every
# network call runs under `timeout`. `tether probe` keeps its own host record
# and its own unreachable-host backoff, so a failure is never cached twice.
# `tether plan` is a cache read; its plan and hop are copied into the row so
# the display never re-decides the tier.

readonly SOURCE_NAME="remote-seshy"
# Wrapped in /bin/sh: the remote login shell may be nushell, which rejects `||`
# and `$VAR`, and every host this reaches has /bin/sh. Exit 3 distinguishes
# "host reachable, seshy absent" from "host unreachable".
readonly REMOTE_PROBE="/bin/sh -c 'command -v sy > /dev/null 2>&1 || exit 3; sy list --json'"
readonly PROBE_TIMEOUT=8
readonly SSH_TIMEOUT=10
readonly PLAN_TIMEOUT=5

config_file="${1:?usage: roster-provider-remote-seshy <sources.json>}"

request="$(cat)"
capability="$(jq -r '.capability // ""' <<< "${request}")"
request_id="$(jq -r '.requestId // ""' <<< "${request}")"

result() {
  jq -cn --arg id "${request_id}" --arg status "$1" --argjson output "$2" \
    '{version: "provider/v1", kind: "result", requestId: $id, status: $status, output: $output}'
}

fail() {
  jq -cn --arg id "${request_id}" --arg message "$1" \
    '{version: "provider/v1", kind: "result", requestId: $id, status: "error", message: $message}'
}

# Prints the tether plan document for one session, or for the host alone when
# the name is empty, or null when tether wrote nothing readable. A plan with
# status "error" exits 1 and still prints, and that document is what the row
# must carry.
plan_for() {
  local host="$1" name="$2" attach="$3"
  local -a inner=()
  mapfile -t inner < <(jq -r '.[]' <<< "${attach}")
  local -a session=()
  if [[ -n ${name} ]]; then
    session=(--session "${name}")
    inner+=("${name}")
  fi
  local plan
  plan="$(timeout "${PLAN_TIMEOUT}" tether plan --host "${host}" "${session[@]}" \
    --native "ssh:${host}" -- "${inner[@]}" 2> /dev/null)" || true
  if [[ -n ${plan} ]] && jq -e 'type == "object"' <<< "${plan}" > /dev/null 2>&1; then
    printf '%s\n' "${plan}"
  else
    printf 'null\n'
  fi
}

# Appends one group and its rows for a host to the two accumulator files.
list_host() {
  local host="$1" attach="$2" groups_file="$3" rows_file="$4"

  timeout "${PROBE_TIMEOUT}" tether probe --host "${host}" > /dev/null 2>&1 || true

  local payload="" status=0
  payload="$(timeout "${SSH_TIMEOUT}" ssh -o BatchMode=yes -o ConnectTimeout=5 "${host}" \
    "${REMOTE_PROBE}" 2> /dev/null)" || status=$?

  local sessions='[]'
  if [[ ${status} -eq 0 ]]; then
    if [[ -n ${payload} ]]; then
      sessions="$(jq -c 'if . == null then [] else . end' <<< "${payload}" 2> /dev/null)" || status=4
    fi
  fi

  if [[ ${status} -ne 0 ]]; then
    local reason
    case "${status}" in
      3) reason="seshy not installed" ;;
      4) reason="unreadable sy output" ;;
      124) reason="timed out" ;;
      255) reason="unreachable" ;;
      *) reason="probe failed (${status})" ;;
    esac
    jq -cn --arg host "${host}" --arg reason "${reason}" \
      '{id: ("host:" + $host), label: $host, glyph: "md_server", ok: false, stale: false, reason: $reason, meta: {}}' \
      >> "${groups_file}"
    return 0
  fi

  # The host's own plan is what the group shows: which tier wins right now and
  # whether the inventory behind it is stale, with or without any session.
  local host_plan
  host_plan="$(plan_for "${host}" "" "${attach}")"

  local name path plan
  while IFS=$'\t' read -r name path; do
    [[ -n ${name} ]] || continue
    plan="$(plan_for "${host}" "${name}" "${attach}")"
    # A native hop runs at the ssh domain, in the session's own directory. A
    # local hop runs the hop tool in a local pane, where a remote directory
    # would fail the spawn, so the plan keeps no cwd there.
    jq -cn --arg source "${SOURCE_NAME}" --arg host "${host}" --arg name "${name}" \
      --arg path "${path}" --argjson attach "${attach}" --argjson plan "${plan}" '
      {
        id: ($source + ":" + $host + ":" + $name),
        workspace: ($host + ":" + $name),
        label: $name,
        group: ("host:" + $host),
        kind: "session",
        host: $host,
        cwd: $path,
        status: null,
        pane: null,
        spawn: (
          if ($plan | type) == "object" and ($plan.plan | type) == "object" and ($plan.hop | type) == "object" then
            {
              plan: {
                command: ($plan.plan.command // []),
                cwd: ($plan.plan.cwd // (if $plan.hop.kind == "native" then $path else "" end)),
                environment: ($plan.plan.environment // {}),
                successCodes: ($plan.plan.successCodes // [0])
              },
              hop: $plan.hop
            }
          else
            {
              plan: {command: ($attach + [$name]), cwd: $path, environment: {}, successCodes: [0]},
              hop: {kind: "native", ref: ("ssh:" + $host)}
            }
          end
        ),
        meta: {
          tier: ($plan.chosen.tier // null),
          loses: ($plan.loses // []),
          stale: ($plan.probe.stale // false),
          status: ($plan.status // "missing")
        }
      }' >> "${rows_file}"
  done < <(jq -r '.[] | [.name, .path] | @tsv' <<< "${sessions}")

  jq -cn --arg host "${host}" --argjson plan "${host_plan}" '
    {
      id: ("host:" + $host),
      label: $host,
      glyph: "md_server",
      ok: true,
      stale: ($plan.probe.stale // false),
      reason: null,
      meta: {tier: ($plan.chosen.tier // null), loses: ($plan.loses // [])}
    }' >> "${groups_file}"
}

list() {
  local attach
  attach="$(jq -c '.attach // ["zmx", "attach"]' "${config_file}")"

  local work
  work="$(mktemp -d)"
  trap 'rm -rf "${work}"' RETURN
  local groups_file="${work}/groups.jsonl" rows_file="${work}/rows.jsonl"
  : > "${groups_file}"
  : > "${rows_file}"

  local host
  while IFS= read -r host; do
    [[ -n ${host} ]] || continue
    list_host "${host}" "${attach}" "${groups_file}" "${rows_file}"
  done < <(jq -r '.hosts[]' "${config_file}")

  local document
  document="$(jq -cn --arg source "${SOURCE_NAME}" \
    --slurpfile groups "${groups_file}" --slurpfile rows "${rows_file}" '
    {
      version: "roster.catalog/v1",
      source: $source,
      ttl: "30s",
      display: {label: "remote", glyph: "md_server", order: 20},
      groups: $groups,
      rows: $rows
    }')"
  result ok "${document}"
}

case "${capability}" in
  provider.validate)
    result ok '{"ok": true}'
    ;;
  source.list)
    list
    ;;
  *)
    fail "unsupported capability ${capability}"
    ;;
esac
