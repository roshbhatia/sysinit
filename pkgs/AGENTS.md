# Agent context for pkgs/

Read this before changing anything under `pkgs/`.

## One module, six tools

`pkgs/go.mod` declares `github.com/roshbhatia/sysinit/pkgs`. Every Go tool here
is a directory inside it, not a module of its own. There is one `go.sum` and one
vendor hash.

```
pkgs/
  go.mod  go.sum
  internal/         shared by every tool
    paths/          XDG homes and the sysinit paths manifest
    git/            one git exec wrapper, with the env scrub
    ui/             ANSI colors and stderr messages
    diffview/       a diff drawn as a symbol tree, with call edges
    workspace/      the declared boundary, and the repositories under it
  ask/              main package + ask/internal/
  changes/          main package + changes/internal/
  traces/           main package + traces/internal/  (source/ holds the provider
                    contract, transcript/ what Claude Code writes to disk,
                    attach/ the cwd to session mapping, ui/live.go the layout)
  seshy/            main package + seshy/internal/
  specutil/         cmd/specutil + specutil/internal/
  utils/            main package + utils/internal/
  prose-style/      rules.cue, not Go
```

Go's `internal/` rule does the enforcement. `pkgs/internal/x` is reachable from
every tool. `pkgs/seshy/internal/x` is reachable from seshy alone. So put a
thing in `pkgs/internal/` only when a second tool needs it, and leave it in the
tool otherwise.

## What belongs in pkgs/internal/

`paths` is the one reader of `~/.local/state/sysinit/paths.json`, which nix
generates from `modules/shared/options/paths-layout.json`. Resolve a state or
config directory through `paths.StateHome()`, `paths.ConfigHome()`, or a named
accessor such as `paths.SeshySessions()`. Do not read `XDG_STATE_HOME` directly;
that is what produced four copies of the same fallback.

`git` scrubs `GIT_DIR`, `GIT_WORK_TREE`, and `GIT_INDEX_FILE` on every call. An
inherited one silently retargets a command that already names its repository.
Call `git.Output` rather than `exec.Command("git", ...)`.

`diffview` renders a unified diff. It owns the join between three layers that
each carry a file and a line: git for the moved lines, an outline for the
symbol ranges, and a call graph for the edges the edit added or removed. It
reads no tool itself, so `changes` feeds it ast-grep and calldiff while traces's
mockup feeds it fixtures.

`workspace` owns the boundary rule: `$SYSINIT_WORKSPACE` when the directory sits
inside it, then the git top level, then the directory. `Roots` lists every
repository under it. `utils` and `changes` both read it, so a seshy session means
the same thing to both.

## Build

`overlays/sysinit-gotools.nix` builds the whole module once as `sysinit-gotools`,
then publishes each tool as a symlink or wrapper selection over its `bin/`. A
change to any tool rebuilds every one of them, which takes seconds.

A tool that shells out to another binary is wrapped rather than symlinked, so
its PATH is declared instead of inherited. `changes` needs git, ast-grep and
calldiff; without them its layers drop out silently, which is the worst kind of
missing dependency.

This repository has no Go tests. `overlays/sysinit-gotools.nix` sets
`doCheck = false`, so `go build` is the only gate. `hack/lint.sh` does not run
`go test` either.

## Adding a tool

Add `pkgs/<name>/` with a `main` package, add its requires to `pkgs/go.mod`,
refresh the vendor hash, and add a `select` entry in `overlays/sysinit-gotools.nix`.
The binary is named after the directory holding `package main`.
