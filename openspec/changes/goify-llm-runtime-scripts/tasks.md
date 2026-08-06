## 1. Scaffold the Go module

- **SHAPE** graph

- [ ] 1.1 Add `pkgs/sysinit-agent/` with `go.mod`, a `main.go` dispatching on
      subcommand, and an `internal/store` package holding the lock directory,
      atomic publish, and control-byte sanitization that `diffnote.sh` and
      `citelock.sh` both implement today. `deps:` none
- [ ] 1.2 Package it with `buildGoModule` in `overlays/`, exposed as
      `pkgs.sysinit-agent`. `deps:` 1.1
- [ ] 1.3 Verify: `nix build` on the new package succeeds and
      `./result/bin/sysinit-agent --help` lists no subcommands yet.
      `deps:` 1.2

## 2. Tier A, diffnote

- **SHAPE** loop
- **STOP** `nix flake check` exits 0 with `checks/diffnote-roundtrip.nix`
  unmodified, and `go test ./...` exits 0
- **MAX-ITERS** 4
- TERMINAL: CAPPED at 4 iterations, or STALLED after 2 iterations with the same
  failing test. On either, stop and report which behavior in the shell original
  could not be reproduced.

- [ ] 2.1 Gather: back up `$(diffnote path)`, and capture
      `diffnote list --json` on a real store as a fixture.
- [ ] 2.2 Gather: enumerate every documented edge case in `diffnote.sh` as a
      test name. The comments are the specification: zero-byte store is
      absorbing, symlinked store refused, malformed store refused, lock is
      per-store and released on interrupt, control bytes stripped on input,
      `--line` rejects leading zeros, path must resolve inside the repo root.
- [ ] 2.3 Act: implement `sysinit-agent diffnote` with `add`, `apply`, `list`,
      `clear`, and `path`, plus the `--replace` scope, and one Go test per name
      from 2.2.
- [ ] 2.4 Verify: `go test ./...` green, and the 2.1 fixture reproduces byte for
      byte through the Go path. Iterate 2.3 if not.
- [ ] 2.5 Act: switch packaging to the binary plus a `diffnote` shim, deleting
      `runtime/diffnote.sh` in the same commit.
- [ ] 2.6 Verify: `nix flake check` with `checks/diffnote-roundtrip.nix`
      unmodified.
- [ ] 2.7 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the locking and atomic-publish paths, which are where
      the shell original accumulated the most defects.

## 3. Tier A, citelock

- **SHAPE** graph

- [ ] 3.1 Enumerate `citelock.sh`'s edge cases as test names, same method as
      2.2. `deps:` 2.6
- [ ] 3.2 Implement `sysinit-agent citelock` reusing `internal/store`, with a
      test per name. `deps:` 3.1
- [ ] 3.3 Verify: `go test ./...` green and `checks/citelock.nix` passes
      unmodified. `deps:` 3.2
- [ ] 3.4 Act: switch packaging to a `citelock` shim, deleting
      `skills/citation-verification/citelock.sh`. `deps:` 3.3

## 4. Ship Tier A

- **SHAPE** graph

- [ ] 4.1 Verify: `nix flake check` and `nh darwin build` both green.
      `deps:` 3.4
- [ ] 4.2 Confirm: owner spot-check. Open CodeDiff on a repo with notes and see
      them render; run `diffnote list` and `citelock` by name. `deps:` 4.1
- [ ] 4.3 Apply: `nh darwin switch`. `deps:` 4.2
- [ ] 4.4 Confirm: after one working day of real use, `diffnote list --json`
      still parses and no note is missing against the 2.1 backup. This gate
      blocks phase 5. `deps:` 4.3

## 5. Tier B, hot path

- **SHAPE** graph

- [ ] 5.1 Implement `sysinit-agent agent-state`, preserving the file-bus layout
      the wezterm surfaces read and the `TMUX_PANE` keying. `deps:` 4.4
- [ ] 5.2 Verify: `checks/agent-sessions-rollup.nix` and the wezterm surfaces
      still resolve state; `SUPER+g` still jumps. `deps:` 5.1
- [ ] 5.3 Implement `sysinit-agent statusline`. `deps:` 4.4
- [ ] 5.4 Verify: `hyperfine` shows the Go `agent-state` faster than the shell
      original it replaced. `deps:` 5.1
- [ ] 5.5 Apply: `nh darwin switch` carrying 5.1 and 5.3 only. `deps:` 5.2, 5.4

## 6. Tier B, deny path

- **SHAPE** loop
- **STOP** `checks/destructive-guard-fixtures.nix` and
  `checks/exit-code-guard-blocks.nix` both pass, and a Go test exists per
  fixture case
- **MAX-ITERS** 3
- TERMINAL: CAPPED at 3, or STALLED with the same fixture failing twice. On
  either, abandon the guard migration and leave both scripts in bash; a guard
  that fails open is worse than an unmigrated one.

- [ ] 6.1 Gather: enumerate every fixture case in both checks as a Go test name.
- [ ] 6.2 Act: implement `sysinit-agent bash-guard` and
      `sysinit-agent exit-code-guard`.
- [ ] 6.3 Verify: both checks pass, and each denies on an injected permitted
      command to prove the test is load-bearing. Iterate 6.2 if not.
- [ ] 6.4 Confirm: owner reviews the deny logic directly. This is the
      human-owned decision from the proposal; automation cannot approve a
      security gate.
- [ ] 6.5 Apply: `nh darwin switch`.

## 7. Close out

- **SHAPE** graph

- [ ] 7.1 Verify: `rg 'jq ' modules/home/programs/llm/runtime/` returns no hit
      for any migrated script. `deps:` 6.5
- [ ] 7.2 Confirm: record in the proposal whether Tier C follows, which is the
      second human-owned decision. `deps:` 7.1
