# Agent context for pkgs/

Read this before changing anything under `pkgs/`.

## One Go module

`pkgs/go.mod` declares `github.com/roshbhatia/sysinit/pkgs`. Everything Go
here is a directory inside it, not a module of its own. There is one `go.sum`
and one vendor hash.

```
pkgs/
  go.mod  go.sum
  utils/            main package + utils/internal/   (one binary, many names)
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

## utils and the hook layer

The hook layer is [gate](https://github.com/roshbhatia/gate): `gate hook` runs
the chain `modules/home/programs/llm/gate.nix` declares, and the generic
providers (`bash-guard`, `nix-guard`, `read-router`, `lint-gate`, `loop-gate`,
`review-gate`, the `review` ledger) live in that repository's `extras/`. They
used to be packages here; `internal/guard`, `internal/lintgate`, and
`internal/loopgate` were moved out in 2026-09.

`utils/main.go` dispatches on `argv[0]`, so one binary answers to its names.
No gate provider lives here. `prose-gate` moved to gate's `extras/` in
2026-09. The rules live in `roshbhatia/prose-style` and reach gate through
`modules/home/programs/llm/gate-defaults.nix`. Sysinit retains desktop integration
commands. `go-utils` owns shared Git, path, and workspace primitives.

### What the model can and cannot see

Claude Code shows a PreToolUse `permissionDecisionReason` to the model only on
a `deny`. On an `allow` it goes to the user. A gate that rewrites the input and
wants the model to know puts the note in `Outcome.Context`, which renders as
`additionalContext`. A Stop hook has no passive channel: `additionalContext` on
Stop continues the turn exactly as `decision: block` does, so gate's
`prose-gate` records on Stop and speaks on the next prompt.

## Build

`overlays/sysinit-gotools.nix` builds the module once as `sysinit-gotools`,
then publishes `utils` under every name in its `links` list, each a wrapper
that pins `git` and `curl` on PATH.
Adding a command means a `commands` entry and a `links` entry in `main.go`,
and the same name in the overlay's `links`. `main_test.go` compares the Go command and link maps. Check overlay aliases when
changing either map.

`buildGoModule` runs the Go tests during its check phase, and the `go-tests`
flake check builds that package, so `nix flake check` covers them. From a
checkout, `cd pkgs && go test ./utils/...` is the fast path.
