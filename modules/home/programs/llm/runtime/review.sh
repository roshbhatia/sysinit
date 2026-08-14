#!/usr/bin/env bash

set -euo pipefail

die() {
  echo "review: $*" >&2
  exit 1
}

command -v utils > /dev/null 2>&1 ||
  die "utils is not on PATH, so the note record cannot be located"

record=$(utils note path)
export_file=$(utils note path --export)

if [ -s "$record" ] && [ ! -s "$export_file" ]; then
  die "$record holds notes but $export_file is missing. Run: utils note rebuild"
fi

if [ ! -s "$export_file" ]; then
  exec hunk diff "$@"
fi

exec hunk diff --agent-context "$export_file" --agent-notes "$@"
