# Agent context for pkgs/

Read this before changing anything under `pkgs/`.

## One module, four tools

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
  ask/              main package + ask/internal/
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

## Build

`overlays/sysinit-gotools.nix` builds the whole module once as `sysinit-gotools`, then
publishes `seshy`, `specutil`, `ask`, and `sysinit-utils` as symlink or wrapper
selections over its `bin/`. A change to any tool rebuilds all four, which takes
seconds.

Do not set `subPackages`. It narrows the check phase as well as the build, and
the `main` packages hold no tests, so the build would pass having run nothing.

`go test ./...` covers every tool, and `overlays/sysinit-gotools.nix` runs it as the
check phase. A test that shells out to `git` works, because `git` is in
`nativeCheckInputs`.

## Adding a tool

Add `pkgs/<name>/` with a `main` package, add its requires to `pkgs/go.mod`,
refresh the vendor hash, and add a `select` entry in `overlays/sysinit-gotools.nix`.
The binary is named after the directory holding `package main`.
