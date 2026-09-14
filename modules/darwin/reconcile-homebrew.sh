#!/usr/bin/env bash
set -euo pipefail

state="$1"
snapshot="$2"
check="$3"
reconcile="$4"
work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT

"$snapshot" > "$work/inventory"
if cmp -s "$state" "$work/inventory" && "$check"; then
  echo 'sysinit: Homebrew configuration and inventory are unchanged' >&2
  exit 0
fi

"$reconcile"
"$check"
"$snapshot" > "$work/inventory"
mkdir -p "$(dirname "$state")"
install -m 600 "$work/inventory" "$state"
