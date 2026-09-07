# Agent context for pkgs/

Read this before changing anything under `pkgs/`.

## One module, two directories

`pkgs/go.mod` declares `github.com/roshbhatia/sysinit/pkgs`. Everything Go
here is a directory inside it, not a module of its own. There is one `go.sum`
and one vendor hash.

```
pkgs/
  go.mod  go.sum
  utils/            main package + utils/internal/   (one binary, many names)
  prose-style/      rules.cue, not Go
```

`ask`, `changes`, `traces`, `seshy`, `specutil`, and `colchis` used to live
here as sibling directories. Each is now its own repository, pinned as a flake
input in `flake.nix` and re-exported by `overlays/inputs.nix`. This file
described "one module, seven tools" for months after that move; the layout
above is the current one.

`utils` reads XDG homes through `github.com/roshbhatia/go-utils/paths`, which
is the one reader of the paths manifest nix generates from
`modules/shared/options/paths-layout.json`. Do not read `XDG_STATE_HOME`
directly; that is what produced four copies of the same fallback.

## utils is the hook layer

`utils/main.go` dispatches on `argv[0]`, so one binary answers to twenty names.
The names that a harness calls from a hook are the gates:

| Name | Event | Decision |
| --- | --- | --- |
| `bash-guard` | PreToolUse Bash | deny a destructive command; deny `cat`/`less`/`more`/`bat` of one file over 16 KiB and name the cheap reader; bound any other unbounded printer with `head -c 16K` and say so |
| `read-guard` | PreToolUse Read | deny an unbounded Read of a file over 16 KiB and name the alternatives: a ranged Read, or `ask -t bulk-read` |
| `nix-guard` | PreToolUse Edit/Write | deny a write that resolves into `/nix/store` |
| `lint-gate` | PostToolUse Edit/Write | run the file's linter, hand failures back as context |
| `loop-gate` | Stop | hold the turn until an armed command passes; CLEAN, CAPPED, STALLED |
| `prose-gate check` | Stop | record the style tells of the reply; never blocks |
| `prose-gate remind` | UserPromptSubmit | the style reminder, with the recorded tells when there are some |
| `prose-gate report` | PostToolUse Agent | note to the caller when a teammate report is over 6 KiB |

Every gate returns a `hookfmt.Outcome` and `hookfmt.Emit` renders it for the
harness: `--format claude` (hook JSON), `exit-code` (gemini and any harness that
reads only the status), or `json` (the envelope an adapter reads). The decision
and the wire shape are separate on purpose, so a gate is written once.

### What the model can and cannot see

Claude Code shows a PreToolUse `permissionDecisionReason` to the model only on
a `deny`. On an `allow` it goes to the user. So:

- A gate that rewrites the input (`updatedInput`) and wants the model to know
  puts the note in `Outcome.Context`, which renders as `additionalContext`.
  `bash-guard`'s output bound does this. Before `Context` existed the bound was
  silent to the model, and a critic reading a cut `git diff` reported the cut
  part as missing from the tree.
- A gate that wants the model to choose an alternative denies and says so in
  `Message`. `read-guard` does this rather than clipping.
- A Stop hook has no passive channel: `additionalContext` on Stop continues the
  turn exactly as `decision: block` does. A note about the reply just sent
  therefore waits for the next `UserPromptSubmit`. `prose-gate` records on Stop
  and speaks on remind.

## Build

`overlays/sysinit-gotools.nix` builds the module once as `sysinit-gotools`,
then publishes `utils` under every name in its `links` list, each a wrapper
that pins `git`, `curl`, and `vale` on PATH and sets `SYSINIT_PROSE_STYLE`.
Adding a command means a `commands` entry and a `links` entry in `main.go`,
and the same name in the overlay's `links`. `main_test.go` fails when the two
disagree.

`buildGoModule` runs the Go tests during its check phase, and the `go-tests`
flake check builds that package, so `nix flake check` covers them. From a
checkout, `cd pkgs && go test ./utils/...` is the fast path.
