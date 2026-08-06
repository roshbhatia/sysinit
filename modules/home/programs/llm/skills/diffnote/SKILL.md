---
description: Leaves review notes on a working-tree diff with the `diffnote` CLI, so a non-obvious change carries its reason to whoever reads the diff later. Notes render as inline virtual text in neovim's CodeDiff view and as a quickfix list. Use when making a change a reader would question: a hidden constraint, a workaround for a specific bug, a rejected alternative, or an edit whose reason is not visible in the diff. Do NOT use for routine edits, which the diff already explains.
allowed-tools: Bash(diffnote:*)
---

> Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST.

`diffnote` writes one JSON file per repository. The editor watches that file, so
a note written with no editor running is there when the view next opens. The CLI
is a pure writer and never talks to the editor.

## When to write one

Write a note when the diff shows WHAT changed but not WHY, and the why would not
be obvious to someone reading the change cold:

- a constraint that is not visible in the changed lines
- a workaround for a specific upstream bug, with its issue number
- an alternative that was tried and rejected, with the reason
- an invariant the next editor could break without noticing

Do not note a rename, a formatting pass, or a change whose reason is its own
diff. Notes accumulate and nothing prunes the store, so a note that adds nothing
costs the reader attention on every later review.

## Commands

```bash
diffnote add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--replace]
diffnote apply --stdin      # batch; accepts {"notes":[…]} or hunk's {"comments":[…]}
diffnote list [--file <path>] [--json]
diffnote clear [--file <path>] [--yes]
diffnote path               # the store this repository resolves to
```

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

## What the reader sees

One line of end-of-line virtual text per annotated line, showing the author and
the summary. Extra notes on the same line collapse to a count. The rationale is
not inline; it is in the quickfix list (`<leader>dn`) and the float
(`<leader>dN`).

So the summary MUST stand alone. A summary of "see rationale" renders as nothing
useful.

## Anchoring

A note stores a line number and nothing re-anchors it when a later edit shifts
the file. A stale line clamps to the end of the buffer rather than disappearing.

Two consequences:

- write the note close in time to the edit it describes
- prefer `--replace` over accumulating notes on a line you keep editing
