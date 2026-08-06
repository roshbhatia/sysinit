## Context

Six scripts under `modules/home/programs/llm/runtime/` and
`modules/home/programs/llm/harnesses/claude/` are packaged today with
`pkgs.writeShellApplication`, wired in `runtime/default.nix`. Each becomes a
standalone command on PATH via the home profile.

The closest existing pattern for a compiled tool is `specutil`, already a Go
binary on PATH and consumed by skills. It proves the packaging shape works on
this host, but it lives in its own repository, so it is a precedent for the
runtime shape rather than a place to add code.

The closest in-repo pattern for a multi-file source tree built by Nix is the
`overlays/*.nix` set, which packages third-party sources. None of them build
first-party code, so this change introduces the first in-repo compiled artifact.

Two consumers constrain the on-disk formats and cannot be changed unilaterally:
`modules/home/programs/neovim/config/lua/harness/diffnote.lua` reads the note
store, and the wezterm surfaces read the agent-state file bus.

## Goals / Non-Goals

Goals:
- remove hand-rolled `jq` state machines from the two scripts that carry the
  most accumulated failure history
- cut per-tool-call latency on the four hot-path scripts by removing fork-per-`jq`
- gain real unit tests for locking, atomicity, and sanitization, which the
  current `checks/` derivations can only test end to end
- keep every caller unchanged

Non-Goals:
- no on-disk format change
- no CLI surface change
- no migration of Tier C or D scripts
- no replacement of the `checks/` derivations; they are the safety net, not a
  casualty

## Decisions

- Decision: one multi-call binary, `sysinit-agent`, with a subcommand per
  migrated script, plus a `writeShellApplication` shim per current command name.
  - Alternative rejected: one Go package and one binary per command. It gives a
    cleaner `command -v` story but multiplies `buildGoModule` invocations and
    build time by six, and every command shares the same store, lock, and
    sanitization code, so separate binaries would either duplicate it or need an
    internal module anyway.

- Decision: shims exec the subcommand rather than symlinking argv[0] dispatch.
  - Alternative rejected: busybox-style `argv[0]` dispatch. It removes the shims
    but makes the binary's behavior depend on its install path, which is
    invisible at the call site and hostile to debugging.

- Decision: the Go module lives in `pkgs/sysinit-agent/` inside this repository.
  - Alternative rejected: a separate repository like `specutil`. A separate repo
    needs its own flake input and a two-repo commit dance for every change,
    which is the exact friction the `sysinit.laurel` split already imposes once.

- Decision: migrate Tier A and Tier B in two separate switches, Tier A first.
  - Alternative rejected: one switch carrying all six. A regression would not be
    bisectable to a tier, and the deny-path scripts in Tier B fail open, so they
    must not land in the same change as the store rewrites.

- Decision: port the existing edge-case comments into Go tests rather than into
  Go comments.
  - Alternative rejected: carrying the comments across verbatim. Each comment
    records a defect that was once live; a test asserts it stays fixed, whereas
    a comment only asserts someone once knew.

- Decision: keep `jq` available on PATH.
  - Alternative rejected: dropping `jq` from `packages.nix` once the migrated
    paths stop using it. Tier C and D scripts and the owner's interactive use
    both still need it.

## Rollout & Gating

Standard repo sequence per tier: edit, `nix flake check`, `nh darwin build`,
owner spot-check, `nh darwin switch`.

Two deviations:

- Tier A must be in production use for at least one working day before Tier B
  starts. The store rewrites are the ones that can lose owner data, and a day of
  real use is the only way to surface a locking defect that a test misses.
- Tier B's two guard scripts land last within their tier, after `agent-state`
  and `statusline`, and only with `checks/destructive-guard-fixtures.nix`
  passing. A guard that fails open is worse than no migration.

Kill switch: each tier is one commit. Reverting it restores the
`writeShellApplication` bodies unchanged, because the shell sources are deleted
in the same commit that adds the Go implementation and are therefore restored
together. No on-disk format changes, so a revert reads existing stores.

## Risks / Trade-offs

- A Go defect corrupts a note store the owner has real notes in -> back up
  `$(diffnote path)` before the first Tier A switch, and assert store validity
  in a Go test before any write path is exercised.
- A rewritten `bash-guard` fails open and permits a destructive command ->
  land it last, gate on `checks/destructive-guard-fixtures.nix`, and add a Go
  test per fixture case rather than trusting the derivation alone.
- The Go and Lua halves drift on the note-path derivation ->
  `checks/diffnote-roundtrip.nix` already pins this from both sides and is kept
  unmodified, so drift fails the build.
- Build time grows with a Go toolchain in the closure -> accepted; the toolchain
  is cached and the binary is small, and the hot-path latency win is paid back
  on every tool call.
- The owner loses the ability to read a script and understand it without a
  compiler -> accepted deliberately, and the reason this stops at Tier B: Tier D
  scripts stay in bash precisely so the glue layer remains readable.

## Adversarial Review

Rubric: the proposal's Behavior criteria, the Decisions and their rejected
alternatives above, the Rollout & Gating sequence, and the proposal Non-goals.

The deterministic `specutil check` gate runs on this change. The critic loop is
owner-gated per the `adversarial-review` skill, and is risk-justified for two
slices specifically: the `internal/store` locking and atomic-publish path, which
is where the shell original accumulated its documented defects, and the deny
path in phase 6, where a regression fails open. Critics attempt to break a slice
with a concrete failing scenario naming a violated rubric item; the author
revises against surviving objections; the loop repeats until no objection
survives or K=4 rounds. Executor: in-process teammate critics under Claude Code,
subagents elsewhere.

## Open Questions

- Whether `citelock` should share `internal/store` at all. Its lock file is a
  citations lock rather than a note store, and the shapes may diverge enough
  that sharing costs more than it saves. Decide during phase 3.1, not before.

## Migration Plan

Per tier, in order:

1. Verify: capture the current behavior. For Tier A, run `diffnote list --json`
   and `citelock` against a real store and save the output as a fixture.
2. Verify: back up `$(diffnote path)` to a location outside the store directory.
3. Add the Go implementation and its tests, leaving the shell scripts in place
   and unpackaged. `nix flake check` passes with both present.
4. Verify: `go test ./...` green, and the captured fixture reproduces byte for
   byte through the Go path.
5. Switch packaging to the Go binary plus shims and delete the shell source in
   the same commit.
6. Verify: `nix flake check`, then `nh darwin build`.
7. Confirm: owner spot-check. Open CodeDiff on a repo with notes and see them
   render; run each migrated command by its current name.
8. Apply: `nh darwin switch`.
9. Confirm: after a working day of use, the store is still valid
   (`diffnote list --json` parses) and no note was lost against the backup.

Rollback: revert the tier's commit and switch. The store format is unchanged, so
the restored shell implementation reads whatever the Go build wrote.
