---
description: Leaves review notes on a working-tree diff with `sysinit-agent note`, so a non-obvious change carries its reason to whoever reads the diff later. Notes are read back with `review`, which is the `hunk` diff viewer with this repository's notes attached. Use when making a change a reader would question: a hidden constraint, a workaround for a specific bug, a rejected alternative, or an edit whose reason is not visible in the diff. Do NOT use for routine edits, which the diff already explains.
allowed-tools: Bash(sysinit-agent:*)
---

> Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST.

`sysinit-agent note` writes one JSON record per repository and one export derived
from it. It is a pure writer: it never opens, launches, or nudges anything. The
owner reads the notes back by running `review`, which is `hunk` with the export
attached, and a note written while nothing is open is there whenever `review`
next runs.

## When to write one

Write a note when the diff shows WHAT changed but not WHY, and the why would not
be obvious to someone reading the change cold:

- a constraint that is not visible in the changed lines
- a workaround for a specific upstream bug, with its issue number
- an alternative that was tried and rejected, with the reason
- an invariant the next editor could break without noticing

Do not note a rename, a formatting pass, or a change whose reason is its own
diff. Notes accumulate and nothing prunes the record, so a note that adds nothing
costs the reader attention on every later review.

```bash
# good — names a constraint the changed lines do not show
sysinit-agent note add --file overlays/lima.nix --line 12 \
  --summary 'Pinned to the old nixpkgs rev because cctools ld is broken on darwin' \
  --rationale 'Building against current nixpkgs fails at link time; drop the pin once upstream fixes it.'

# bad — restates the diff
sysinit-agent note add --file overlays/lima.nix --line 12 \
  --summary 'Changed the nixpkgs revision'
```

## Writing

```bash
sysinit-agent note add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--replace]
sysinit-agent note apply --stdin
sysinit-agent note list [--file <path>] [--json]
sysinit-agent note clear [--file <path>] [--yes]
sysinit-agent note path
sysinit-agent note rebuild
```

`apply` reads one batch from stdin and accepts either shape:
`{"notes":[…]}` with `file` and `line`, or the viewer's `{"comments":[…]}` with
`filePath` and `newLine`.

Rules:

- `--summary` is one line. It is folded to one line on the way in regardless, so
  write it as one.
- `--rationale` carries the why and keeps its newlines. This is the field that
  makes the note worth writing.
- `--author` SHOULD be your own agent or teammate name. It defaults to `agent`,
  which is useless when more than one teammate touched a file.
- `--replace` drops any existing note with the same file, line, and author
  before appending. Always pass it when re-noting a line you already noted, or
  repeated passes stack.
- `--line` anchors on the MODIFIED side. A batch naming only `oldLine` is
  refused rather than silently anchored at the wrong place.

`rebuild` exists for one case: the record was hand-edited, which is the one route
that changes it without going through a write. Every `add`, `apply`, and `clear`
republishes the export on its own.

`clear` is the only verb here that is not on the allowlist, so it prompts. That is
deliberate: it is the owner's kill switch and it deletes their notes as well as
yours. Do not reach for it to tidy up.

## Reading

The reader is `review`. It runs the `hunk` diff viewer with this repository's
export attached, and passes its own arguments through.

A `review` that is already open does not pick up a note written after it
started. Neither does `review --watch`. Re-run `review` instead. Do not offer to
refresh the owner's open pane for them: there is no route that does it, and
`hunk session reload` drops the notes entirely rather than refreshing them.

For the viewer's own surface, read the skill `hunk` ships rather than a copy of
it here, which would drift on every upgrade:

```bash
hunk skill path
```

That prints a `SKILL.md` path. Read the file it names.

`hunk` is deliberately absent from this skill's `allowed-tools`. `hunk skill path`
is on the read-only allowlist, so it runs without a prompt; anything else `hunk`
does opens a full-screen viewer, which is the owner's to open and never yours.

## What the reader sees

The summary and the author on the annotated line, and the rationale alongside it.
The summary MUST stand alone: a summary of "see rationale" reads as nothing
useful in the list the viewer builds.

## Anchoring

A note stores a line number and nothing re-anchors it when a later edit shifts
the file.

Two consequences:

- write the note close in time to the edit it describes
- prefer `--replace` over accumulating notes on a line you keep editing
