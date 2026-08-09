#!/usr/bin/env bash

set -euo pipefail

# Read the working-tree diff, with this repository's agent notes attached.
#
# Deliberately NOT named `hunk`. A wrapper by that name would be one name for two
# things: it collides with `pkgs.hunk` on `bin/hunk` in a single home profile, and
# `which hunk` could no longer say which one ran. A separate verb composes with
# the tool instead of shadowing it.

die() {
  echo "review: $*" >&2
  exit 1
}

# Loud, not silent. Without the record command there is no way to tell "this
# repository has no notes" from "the note reader is missing", and the second is
# the ordinary state on a box that installed hunk by hand.
command -v sysinit-agent > /dev/null 2>&1 ||
  die "sysinit-agent is not on PATH, so the note record cannot be located"

record=$(sysinit-agent note path)
export_file=$(sysinit-agent note path --export)

# The record without its export is the state every box is in the moment this
# lands: a record written before the export existed. Nothing rebuilds it on its
# own, so say the verb rather than showing a review that silently has no notes.
if [ -s "$record" ] && [ ! -s "$export_file" ]; then
  die "$record holds notes but $export_file is missing. Run: sysinit-agent note rebuild"
fi

# Neither file is the ordinary state of a clean repository, not an error. Omit
# the flag rather than pass a path that does not exist: hunk exits 1 with ENOENT
# on a missing context file, and an empty export synthesized here would write a
# file to answer a question that needs no file.
if [ ! -s "$export_file" ]; then
  exec hunk diff "$@"
fi

# A real path, never `-`. Reading the sidecar from stdin returns a null watch
# plan, which turns `review --watch` into a one-shot with no diagnostic.
#
# `--agent-notes` is not optional here. hunk's own default is `agent_notes =
# false`, so without it the sidecar loads, costs the read, and displays nothing,
# which is indistinguishable from having no notes at all. It goes before "$@" so
# a caller who passes `--no-agent-notes` still wins.
exec hunk diff --agent-context "$export_file" --agent-notes "$@"
