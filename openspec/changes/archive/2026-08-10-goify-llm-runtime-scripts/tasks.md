## 1. Scaffold the Go module

- **SHAPE** graph

- [x] 1.1 Add `pkgs/sysinit-agent/` with `go.mod`, a `main.go` dispatching on
      subcommand, and an `internal/store` package holding the lock directory,
      atomic publish, and control-byte sanitization that `diffnote.sh` and
      `citelock.sh` both implement today. `deps:` none
- [x] 1.2 Package it with `buildGoModule` in `overlays/`, exposed as
      `pkgs.sysinit-agent`. `deps:` 1.1
- [x] 1.3 Verify: `nix build` on the new package succeeds and
      `./result/bin/sysinit-agent --help` lists no subcommands yet.
      `deps:` 1.2
- [x] 1.4 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on `internal/store`, which every later phase depends on.
      `deps:` 1.3
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 2. Tier A, diffnote

- **SHAPE** loop
- **STOP** `nix flake check` exits 0 with `checks/diffnote-roundtrip.nix`
  unmodified, and `go test ./...` exits 0
- **MAX-ITERS** 4
- TERMINAL: CAPPED at 4 iterations, or STALLED after 2 iterations with the same
  failing test. On either, stop and report which behavior in the shell original
  could not be reproduced.

- [x] 2.1 Gather: back up `$(diffnote path)`, and capture
      `diffnote list --json` on a real store as a fixture.
- [x] 2.2 Gather: enumerate every documented edge case in `diffnote.sh` as a
      test name. The comments are the specification: zero-byte store is
      absorbing, symlinked store refused, malformed store refused, lock is
      per-store and released on interrupt, control bytes stripped on input,
      `--line` rejects leading zeros, path must resolve inside the repo root.
- [x] 2.3 Act: implement `sysinit-agent diffnote` with `add`, `apply`, `list`,
      `clear`, and `path`, plus the `--replace` scope, and one Go test per name
      from 2.2.
- [x] 2.4 Verify: `go test ./...` green, and the 2.1 fixture reproduces byte for
      byte through the Go path. Iterate 2.3 if not.
- [x] 2.5 Act: switch packaging to the binary plus a `diffnote` shim, deleting
      `runtime/diffnote.sh` in the same commit.
- [x] 2.6 Verify: `nix flake check` with `checks/diffnote-roundtrip.nix`
      unmodified.
- [x] 2.7 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the locking and atomic-publish paths, which are where
      the shell original accumulated the most defects.
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 3. Tier A, citelock

- **SHAPE** graph

- [x] 3.1 Enumerate `citelock.sh`'s edge cases as test names, same method as
      2.2. `deps:` 2.6
- [x] 3.2 Implement `sysinit-agent citelock` reusing `internal/store`, with a
      test per name. `deps:` 3.1
- [x] 3.3 Verify: `go test ./...` green and `checks/citelock.nix` passes
      unmodified. `deps:` 3.2
- [x] 3.4 Act: switch packaging to a `citelock` shim, deleting
      `skills/citation-verification/citelock.sh`. `deps:` 3.3

- [x] 3.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the lock-format compatibility, since a citations lock
      the offline gate cannot read fails closed on every commit. `deps:` 3.4
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 4. Ship Tier A

- **SHAPE** graph

- [x] 4.1 Verify: `nix flake check` and `nh darwin build` both green.
      `deps:` 3.4
- [x] 4.2 Confirm: owner spot-check. Open CodeDiff on a repo with notes and see
      them render; run `diffnote list` and `citelock` by name. `deps:` 4.1
- [x] 4.3 Apply: `nh darwin switch`. `deps:` 4.2
- [x] 4.4 Confirm: after one working day of real use, `diffnote list --json`
      still parses and no note is missing against the 2.1 backup. This gate
      blocks phase 5. `deps:` 4.3

      Closed on 2026-08-09 with ONE HALF RUN and one half unrunnable. Both are
      recorded, because a gate that blocked phase 5 must not close on a summary.

      The command this task names no longer exists. `make-sysinit-composable`
      phase 3 replaced `diffnote` with a writer and a separate reader, so the
      successor is `sysinit-agent note list --json`. That is a rename of the
      surface this task gates, not a different gate, which is why this closes
      here rather than being dropped.

      The parse half RAN and passes. `sysinit-agent note list --json` exits 0
      and emits a valid envelope: `version: 1`, the repo path, and a `notes`
      array. Nothing about the JSON contract regressed through the Go path.

      The comparison half is NOT ASSERTED and cannot be. The store at
      `~/.local/state/agents/diff-notes/` holds zero notes for this repo, and no
      2.1-era backup is on disk. So "no note is missing against the 2.1 backup"
      has no referent on either side, and "after one working day of real use"
      never happened: there has been no real use to check. Phase 5 shipped
      anyway, months of task numbering ago, so this gate did not in fact block
      it. Recording that is the point.

- [x] 4.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are not justified here; this phase only gates on commands
      and on the owner's own spot-check. `deps:` 4.4
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 5. Tier B, hot path

- **SHAPE** graph

- [x] 5.1 Implement `sysinit-agent agent-state`, preserving the file-bus layout
      the wezterm surfaces read and the `TMUX_PANE` keying. `deps:` 4.4
- [x] 5.2 Verify: `checks/agent-sessions-rollup.nix` and the wezterm surfaces
      still resolve state; `SUPER+g` still jumps. `deps:` 5.1
- [x] 5.3 Implement `sysinit-agent statusline`. `deps:` 4.4
- [x] 5.4 Verify: `hyperfine` shows the Go `agent-state` faster than the shell
      original it replaced. `deps:` 5.1
- [x] 5.5 Apply: `nh darwin switch` carrying 5.1 and 5.3 only. `deps:` 5.2, 5.4

- [x] 5.6 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the file-bus layout, which the wezterm surfaces read
      and no check fully covers. `deps:` 5.5
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 6. Tier B, deny path

- **SHAPE** loop
- **STOP** `nix flake check` exits 0 with `checks/destructive-guard-fixtures.nix`
  and `checks/exit-code-guard-blocks.nix` unmodified, and a Go test exists per
  fixture case
- **MAX-ITERS** 3
- TERMINAL: CAPPED at 3, or STALLED with the same fixture failing twice. On
  either, abandon the guard migration and leave both scripts in bash; a guard
  that fails open is worse than an unmigrated one.

- [x] 6.1 Gather: enumerate every fixture case in both checks as a Go test name.
- [x] 6.2 Act: implement `sysinit-agent bash-guard` and
      `sysinit-agent exit-code-guard`.
- [x] 6.3 Verify: both checks pass, and each denies on an injected permitted
      command to prove the test is load-bearing. Iterate 6.2 if not.
- [x] 6.4 Confirm: owner reviews the deny logic directly. This is the
      human-owned decision from the proposal; automation cannot approve a
      security gate.
- [x] 6.5 Apply: `nh darwin switch`.

- [x] 6.6 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics adversarially against the deny path, whose failure mode
      is to fail open. This is the highest-risk slice in the change.
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.


## 7. Close out

- **SHAPE** graph

- [x] 7.1 Verify: `rg 'jq ' modules/home/programs/llm/runtime/` returns no hit
      for any migrated script. `deps:` 6.5
- [x] 7.2 Confirm: record in the proposal whether Tier C follows, which is the
      second human-owned decision. `deps:` 7.1

      Recorded in the proposal: Tier C does NOT follow. Written under the
      owner's standing direction of 2026-08-09 to take the recommendation on a
      decision like this one. Flip it by editing that line in the proposal; this
      task exists so the answer is written down, not so the answer is yes.

      The measurement that decides it. The proposal's premise was 3,646 lines
      across 30 scripts. `modules/home/programs/llm/runtime/` now holds 1,389
      lines and 40 `jq` calls, a 62% reduction, because Tier A and B replaced
      six scripts and `make-sysinit-composable` deleted more. One of the four
      named Tier C candidates, `worklog-query.sh`, no longer exists at all.

      The three that remain do not carry the risk the Go migration was for.
      `agent-sessions.sh` is 218 lines with 13 `jq` calls, `loop-gate.sh` is 142
      with 11, and `agent-notify.sh` is 150 with 1. What justified Go in Tier A
      was a hand-rolled lock directory, an atomic publish, and a
      read-modify-write cycle, which is where `diffnote.sh` had accumulated its
      defects. `loop-gate.sh` and `agent-notify.sh` have no lock, no atomic
      rename, and no trap, and write no state file. They read JSON and branch.

      One exception, named rather than buried. `agent-sessions.sh` does hold one
      lock and one atomic rename, so it alone still has the shape. If any script
      is migrated later it is that one, and it is its own change, not a Tier C
      that carries two scripts along with it that do not need it.
- [x] 7.3 Adversarial review (`adversarial-review` skill): run deterministic
      lint over the whole change; confirm no migrated path still shells out to
      `jq`. `deps:` 7.2

      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone, so no critic ran for this
      phase. `specutil check` passes for the change.

      The `jq` half of this task ran and passes, on the reading 7.1 already
      fixed: no MIGRATED path shells out to `jq`. The six migrated scripts are
      gone from `runtime/`, replaced by shims onto the binary. 40 `jq` calls
      remain across 12 unmigrated scripts, which is Tier C and D territory and
      is what 7.2 decides against pursuing.
