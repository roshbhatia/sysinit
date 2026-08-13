#!/usr/bin/env bash

set -euo pipefail

# Read the working-tree diff, with this repository's agent notes attached.

die() {
  echo "review: $*" >&2
  exit 1
}

# Loud, not silent.
command -v utils > /dev/null 2>&1 ||
  die "utils is not on PATH, so the note record cannot be located"

record=$(utils note path)
export_file=$(utils note path --export)

# The record without its export is the state every box is in the moment this
if [ -s "$record" ] && [ ! -s "$export_file" ]; then
  die "$record holds notes but $export_file is missing. Run: utils note rebuild"
fi

# Neither file is the ordinary state of a clean repository, not an error.
if [ ! -s "$export_file" ]; then
  exec hunk diff "$@"
fi

# A real path, never `-`.
exec hunk diff --agent-context "$export_file" --agent-notes "$@"
