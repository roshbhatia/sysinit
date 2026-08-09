# hunk probe (task 3.1)

Probed 2026-08-08 against the real binary, not the README, via
`nix run github:modem-dev/hunk -- ...` plus its source at
`/nix/store/bdqcvhmxd6b9lkgwmjbl4bbbbvrvjy8x-source`. Version 0.18.0.

Design decision 2 rests on this, and the probe refutes three of its claims. Read
"What this overturns" first.

## What this overturns

Decision 2 says the `hunk session comment add` surface "carries `filePath`, one
line selector, and `summary`. It carries no second body field, no author, and no
upsert. Three of our fields have no target."

All three are wrong, on both of hunk's surfaces.

| claim | verdict | evidence |
| --- | --- | --- |
| no second body field | REFUTED | `rationale` is a first-class field on both surfaces |
| no author | REFUTED | `author` is a first-class field on both surfaces |
| no upsert | REFUTED | annotations carry an optional `id` |

The conclusion decision 2 reached still stands: keep `internal/store`, keep the
writer, delete the renderer and the launcher. What does not stand is one reason
given for it. `--rationale`, `--author`, and `--replace` are NOT data with
nowhere to go, so "deleting them loses data" cannot rest on hunk having no
target for them. They have targets. Task 3.4 keeps them anyway, on the surviving
reason: the record is ours, it outlives any viewer, and the non-Nix path in
phase 9 has no hunk.

A second correction: the sidecar takes a line RANGE, not "one line selector".
`oldRange` and `newRange` are `[start, end]` integer tuples.

## The sidecar schema (`--agent-context`)

Authoritative source is the parser at `src/core/agent.ts`, function
`loadAgentContext` and `normalizeAnnotationFile`. This is the surface task 3.5
writes to. It is undocumented in the bundled skill; the only published example is
`examples/3-agent-review-demo/agent-context.json`.

Root object:

| field | type | required | on absence |
| --- | --- | --- | --- |
| `version` | number | no | defaults to 1 |
| `summary` | string | no | changeset-level summary, omitted |
| `files` | array | no | defaults to `[]` |

File entry. Throws "Agent context files must be objects." for a non-object, and
"Agent context file entries require a non-empty path." for a missing path:

| field | type | required |
| --- | --- | --- |
| `path` | non-empty string | YES |
| `summary` | string | no |
| `annotations` | array | no, defaults to `[]` |

Annotation. Throws "Agent annotations must be objects." for a non-object and
"Each agent annotation requires a summary." for a missing or empty summary:

| field | type | notes |
| --- | --- | --- |
| `summary` | non-empty string | the ONLY required field |
| `id` | string | the upsert key decision 2 says does not exist |
| `oldRange` | `[int, int]` | 1-based, ordered start..end |
| `newRange` | `[int, int]` | same |
| `rationale` | string | the second body field decision 2 says does not exist |
| `author` | string | the author field decision 2 says does not exist |
| `markup` | non-empty string | STML, needs `--experimental` at launch |
| `tags` | string[] | non-strings filtered out |
| `confidence` | `low`\|`medium`\|`high` | anything else becomes undefined |
| `source` | string | |
| `createdAt` | string | |

Three fields exist on the `AgentAnnotation` type in
`src/extension-api/types.ts` but are NOT read by the sidecar parser, so they are
silently dropped: `updatedAt`, `title`, `editable`. Do not write them.

Range validation is strict once a 2-element array is present, and lenient
otherwise. A non-array or a wrong-length array silently becomes `undefined`. A
2-element array with a non-integer throws "Annotation ranges must be integer
tuples."; a value below 1 throws "must use positive 1-based line numbers."; and
`end < start` throws "must be ordered start..end tuples." So a malformed range is
a hard failure but a missing one is not.

`rationale` is a plain string field with no stated length or newline limit, so
task 3.5's multi-line concern is answered: `rationale` keeps its newlines and
nothing has to be flattened. No loss to record in the design.

Two behaviors worth having: `findAgentFileContext` matches a file by `path` and
then by `previousPath`, so annotations survive a rename; and `orderDiffFiles`
uses the sidecar's file order as the narrative order of the review.

## A path that does not exist

Task 3.3 asks this to decide how the no-notes branch is implemented. The answer
forecloses one of the three options it lists.

| input | exit | output |
| --- | --- | --- |
| missing path | 1 | `hunk: ENOENT: no such file or directory, open '...'` |
| malformed sidecar | 1 | `hunk: Each agent annotation requires a summary.` |
| valid sidecar | opens the TUI | reviewed normally |

So `review` MUST NOT pass a missing path through. `hunk` fails hard, and a
repository that never had a note is the ordinary case that 3.3 requires to exit
0. Omit `--agent-context` entirely when there is no export. Synthesizing an empty
export would also work and is worse: it writes a file to answer a question the
caller can answer without one.

`-` is accepted in place of a path and reads the sidecar from stdin.

## `--watch` and replace-by-rename

This is the load-bearing half. `store.Publish` writes a temp, fsyncs, and calls
`os.Rename` (`store.go:124-144`), which installs a NEW INODE. A watcher holding a
descriptor, or watching the file rather than its directory, loses the change.

hunk watches the parent DIRECTORY. `resolveWatchPlan`
(`src/core/watchPlan.ts:138-141`) pushes the sidecar as a file target with
`source: "sidecar"`, and `groupFileTargets` at `:55-86` normalizes every file
target "into deterministic parent-directory groups", keying by
`pathApi.dirname(path)` and tracking the wanted entries inside it.

So a replace-by-rename IS observed, and 3.5's design works: the writer
republishes the export inside the store lock and a running `review --watch` picks
it up. No adapter, no polling, and no need to re-run `review` to see a new note.

One exception, and it is explicit: `--agent-context -` returns a null watch plan
(`watchPlan.ts:102-104`). Reading the sidecar from stdin disables watching
entirely. `review` must pass a real path, never `-`.

## Systems the flake provides

`nix flake show github:modem-dev/hunk` reports packages for exactly:

- `aarch64-darwin`
- `aarch64-linux`
- `x86_64-linux`

That is `cacheSystems` (`flake.nix:109-113`) exactly, so task 3.13's check can be
instantiated on all three with no per-system gating and no restriction. 3.13's
open worry does not materialize: it noted `cacheSystems` has no `x86_64-darwin`
and asked whether coverage would fall short. Coverage matches. The reason 3.2
still pins hunk to its own nixpkgs is unchanged and separate: its build
enumerates `perSystem.x86_64-darwin`, which nixpkgs-unstable dropped, so making
it follow ours breaks its evaluation rather than its coverage.

## The live session surface

Not what 3.5 writes to, recorded because decision 2 cites it.

```
hunk session comment add (<session-id> | --repo <path>) --file <path>
  (--old-line <n> | --new-line <n>) --summary <text>
  [--rationale <text>] [--author <name>] [--markup <stml>] [--focus] [--json]
hunk session comment apply (<session-id> | --repo <path>) --stdin [--focus] [--json]
hunk session comment list (<session-id> | --repo <path>) [--file <path>]
  [--type <live|all|ai|agent|user>] [--json]
hunk session comment rm (<session-id> | --repo <path>) <comment-id> [--json]
hunk session comment clear (<session-id> | --repo <path>) [--file <path>]
  [--include-user|--all] --yes [--json]
hunk session get (<session-id> | --repo <path>) [--json]
```

`comment add` takes one line, not a range, and has no `--replace`; `comment rm`
by id and `comment clear` are how a note goes away. `comment apply` items require
`filePath`, `summary`, and exactly one of `hunk`, `hunkNumber`, `oldLine`, or
`newLine`.

This surface needs a running daemon and a live session, which is why it is not
the one this change writes to. The sidecar needs neither.
