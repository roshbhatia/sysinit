#!/usr/bin/env bash
set -euo pipefail

state="$1"
snapshot="$2"
check="$3"
reconcile="$4"
work=$(mktemp -d)
check_pid=""
cleanup() {
  if [ -n "$check_pid" ]; then wait "$check_pid" || true; fi
  rm -rf "${work:?}"
}
trap cleanup EXIT

"$check" > "$work/check.log" 2>&1 &
check_pid=$!
"$snapshot" > "$work/inventory"
check_status=0
wait "$check_pid" || check_status=$?
check_pid=""
if cmp -s "$state" "$work/inventory" && [ "$check_status" -eq 0 ]; then
  echo 'sysinit: Homebrew configuration and inventory are unchanged' >&2
  exit 0
fi

"$reconcile"
"$check"
"$snapshot" > "$work/inventory"
mkdir -p "$(dirname "$state")"
install -m 600 "$work/inventory" "$state"
