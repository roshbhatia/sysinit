#!/usr/bin/env bash
set -euo pipefail

# Refreshes the per-host seshy session cache that the WezTerm session tree reads.
# WezTerm's lua runs on the GUI thread, so it can never make the ssh call itself:
# it spawns this in the background and reads whatever cache is already on disk.

# Line 1 is the remote login shell, then a sentinel, then `sy list --json`.
# Exit 3 distinguishes "host reachable, seshy absent" from "host unreachable".
readonly REMOTE_PROBE='command -v sy > /dev/null 2>&1 || exit 3
command -v zsh 2> /dev/null || printf "%s\n" /bin/sh
printf "%s\n" ---
sy list --json'

TMP_FILE=""

cleanup() {
  if [[ -n ${TMP_FILE} ]]; then
    rm -f "${TMP_FILE}"
  fi
  return 0
}

refresh_host() {
  local cache_dir="$1"
  local host="$2"
  local dest="${cache_dir}/${host}.json"
  local payload="" status=0

  TMP_FILE="${dest}.tmp.$$"

  payload="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "${host}" "${REMOTE_PROBE}" 2> /dev/null)" || status=$?

  if [[ ${status} -eq 0 ]]; then
    local remote_shell sessions
    remote_shell="$(printf '%s\n' "${payload}" | sed -n '1p')"
    sessions="$(printf '%s\n' "${payload}" | sed '1,/^---$/d')"
    if [[ -z ${sessions} ]]; then
      sessions='[]'
    fi
    if jq -n --arg host "${host}" --arg shell "${remote_shell}" --argjson sessions "${sessions}" \
      '{host: $host, ok: true, shell: $shell, sessions: $sessions}' > "${TMP_FILE}" 2> /dev/null; then
      mv -f "${TMP_FILE}" "${dest}"
      TMP_FILE=""
      return 0
    fi
    status=4
  fi

  local reason
  case "${status}" in
    3) reason="seshy not installed" ;;
    4) reason="unreadable sy output" ;;
    255) reason="unreachable" ;;
    *) reason="probe failed (${status})" ;;
  esac

  jq -n --arg host "${host}" --arg reason "${reason}" \
    '{host: $host, ok: false, reason: $reason, sessions: []}' > "${TMP_FILE}"
  mv -f "${TMP_FILE}" "${dest}"
  TMP_FILE=""
}

main() {
  local cache_dir="${1:?usage: seshy-remote-list <cache-dir> <host>...}"
  shift
  mkdir -p "${cache_dir}"

  local host
  for host in "$@"; do
    refresh_host "${cache_dir}" "${host}"
  done
}

trap cleanup EXIT
main "$@"
