#!/usr/bin/env bash
set -euo pipefail

# A provider/v1 source for roster that lists the local seshy sessions. It is an
# interim adapter: seshy ships its own `source.list` in v4.3, and this file
# goes away when that lands. Until then it reads one request frame on stdin,
# runs `sy list --json`, and answers one result frame whose output is the
# roster.catalog/v1 document minus generated_at, which roster stamps itself.
#
# Row shape: `spawn.plan.command` is empty, which tells the display to run its
# default program in the session's directory over a local hop.

readonly SOURCE_NAME="seshy"

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

list() {
  local sessions status=0
  sessions="$(sy list --json 2> /dev/null)" || status=$?
  if [[ ${status} -ne 0 ]]; then
    fail "sy list --json exited ${status}"
    return 0
  fi
  if [[ -z ${sessions} ]]; then
    sessions='[]'
  fi
  local document
  if ! document="$(jq -c --arg source "${SOURCE_NAME}" '
    (if . == null then [] else . end) as $sessions
    | {
      version: "roster.catalog/v1",
      source: $source,
      ttl: "10s",
      display: {label: "sessions", glyph: "cod_briefcase", order: 10},
      groups: [],
      rows: [$sessions[] | {
        id: ($source + ":" + .name),
        workspace: .name,
        label: .name,
        group: null,
        kind: "session",
        host: null,
        cwd: .path,
        status: null,
        pane: null,
        spawn: {
          plan: {command: [], cwd: .path, environment: {}, successCodes: [0]},
          hop: {kind: "local"}
        },
        meta: {repoCount: .repoCount, lastModified: .lastModified}
      }]
    }' <<< "${sessions}" 2> /dev/null)"; then
    fail "unreadable sy list output"
    return 0
  fi
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
