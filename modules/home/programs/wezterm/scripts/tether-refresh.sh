#!/usr/bin/env bash
set -euo pipefail

# Refreshes tether's view of every configured remote host for the WezTerm
# session tree. WezTerm's lua runs on the GUI thread, so it spawns this in the
# background and reads whatever is already on disk.
#
# `tether probe` is the one ssh round trip. It keeps its own host record and its
# own unreachable-host backoff, so nothing here caches a failure a second time.
# The plan written beside the seshy cache is the display side only: which tier
# wins right now, what that hop loses, and whether the inventory behind it is
# stale. The attach runs its own `tether plan` with the real inner argv.

refresh_host() {
  local cache_dir="$1"
  local host="$2"
  local dest="${cache_dir}/${host}.tether.json"
  local tmp="${dest}.tmp.$$"

  tether probe --host "${host}" > /dev/null 2>&1 || true

  # A plan with status "error" exits 1 and still prints the document, and that
  # document is what the tree must show. Only an empty write is discarded.
  tether plan --host "${host}" --native "ssh:${host}" > "${tmp}" 2> /dev/null || true
  if [[ -s ${tmp} ]]; then
    mv -f "${tmp}" "${dest}"
  else
    rm -f "${tmp}"
  fi
}

main() {
  local cache_dir="${1:?usage: tether-refresh <cache-dir> <host>...}"
  shift
  mkdir -p "${cache_dir}"

  local host
  for host in "$@"; do
    refresh_host "${cache_dir}" "${host}"
  done
}

main "$@"
