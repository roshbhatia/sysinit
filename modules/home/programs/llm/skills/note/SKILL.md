---
description: Leaves review notes on a working-tree diff with `utils note`, so a non-obvious change carries its reason to whoever reads the diff later. The owner reads the notes back in Neovim, drawn on the line each one annotates. Use when making a change a reader would question: a hidden constraint, a workaround for a specific bug, a rejected alternative, or an edit whose reason is not visible in the diff. Do NOT use for routine edits, which the diff already explains.
allowed-tools: Bash(utils:*)
---

> Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST.

`utils note` writes one JSON record. A note is addressed by the absolute path of
the file it annotates, so work spanning several repositories reads back as one
list and a note can be written from anywhere, including a folder that is not a
repository. It is a pure writer: it never opens, launches, or nudges anything.
The owner reads the notes back in Neovim, and a note written while nothing is
open is there the next time Neovim refreshes.

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
utils note add --file overlays/lima.nix --line 12 \
  --summary 'Pinned to the old nixpkgs rev because cctools ld is broken on darwin' \
  --rationale 'Building against current nixpkgs fails at link time; drop the pin once upstream fixes it.'

# bad — restates the diff
utils note add --file overlays/lima.nix --line 12 \
  --summary 'Changed the nixpkgs revision'
```

## Writing

```bash
utils note add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--origin agent|user] [--replace]
utils note answer --id <id> --summary <text> [--rationale <text>] [--author <name>]
utils note list [--file <path>] [--open] [--json]
utils note clear [--id <id>] [--file <path>] [--line <n>] [--yes]
utils note path
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
- `--line` anchors on the MODIFIED side. The write also records the text of that
  line, and a reader re-anchors on the text, so a note follows its line through
  later edits.
- `--file` takes any path you can name. It is stored as an absolute,
  symlink-resolved path, so two spellings of one file cannot produce two notes
  that never see each other.
- `--origin` says who wrote the note, not what they are called. Leave it alone:
  it defaults to `agent`, and `user` belongs to the owner's editor, which draws
  the two differently.

`clear --id` removes exactly one note, which is the only removal that cannot hit
the wrong one after a file has moved. `clear` is the only verb here that is not
on the allowlist, so it prompts. That is
deliberate: it is the owner's kill switch and it deletes their notes as well as
yours, in every repository. Do not reach for it to tidy up. A note of your own that the code has
outgrown is superseded with `add --replace`, which needs no prompt and leaves the
owner's notes alone.

## Answering the owner

The record carries both directions. A note with `"origin": "user"` is the owner
writing to you: a question about a change, or an inline suggestion. It stays
`"state": "open"` until it is answered, and a hook puts the open ones in front of
you at the start of every turn.

```bash
utils note list --open --json
```

Read the code the note names before you reply to it. Then answer by id:

```bash
utils note answer --id 3fb3cee3 --author claude \
  --summary 'It pins the old rev because cctools ld fails at link time' \
  --rationale 'Dropping the pin fails the darwin build; the upstream issue is #1841.'
```

`answer` files your reply on the same line and marks the question answered in one
write. Rules:

- Answer the question. A reply that restates the code the owner is looking at
  reads as an evasion, because the owner already read it.
- Say in the chat what you answered and what you changed, if anything. The note
  is the record; the chat is where the owner finds out it moved.
- Never delete the owner's note to mark it handled. It is theirs, and answering
  is what closes it.
- An open note you cannot answer is a question for the chat, not a note to leave
  waiting.

## Reading

The reader is the owner's Neovim. It draws the summary on the annotated line and
the rationale under it, in a box titled with your icon, or with the owner's git
address for a note they wrote. The summary MUST stand alone: a summary of "see
rationale" reads as nothing useful in the list Neovim builds.

Neovim reads the record on refresh, so a note you write now appears there without
you doing anything. Never open, refresh, or otherwise reach into the owner's
editor. Say in the chat what you noted; opening the surface is theirs.

To read the record yourself, list it:

```bash
utils note list --file <path>
utils note list --json
```

## Anchoring

A note stores a line number and the text of that line. A reader looks for the
text and shows the note wherever it is now. The record is never renumbered, so a
wrong guess is undone by the next read.

The text has to be unique in the file for this to work. A note on a line reading
`end` moves nowhere, because nothing can tell that `end` from the other forty.

Two consequences:

- prefer a line with something on it. A note anchored on `}` stays where the
  line number left it.
- prefer `--replace` over accumulating notes on a line you keep editing.
