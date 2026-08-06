## Why

The shell corpus under `modules/home/programs/llm` is 3,646 lines across 30
scripts, and it is not one thing. Two clusters carry nearly all the risk.

The first cluster hand-rolls JSON state machines in `jq`. `diffnote.sh` is 510
lines with 23 `jq` invocations; `citelock.sh` is 395 with 17. Both implement a
lock directory, an atomic temp-file publish, schema validation, and a
read-modify-write cycle. Every hard-won comment in `diffnote.sh` documents a
bash failure already paid for: a zero-byte store being an absorbing state, `mv
-f` replacing a symlink and emptying its target, a trap whose `|| true` made an
interrupted write report success, last-write-wins with no lock. These are not
lint-catchable, which is the evidence that `shellcheck` and `shfmt` have run out
of road here.

The second cluster runs on the hot path. `agent-state.sh`, `bash-guard.sh`, and
`exit-code-guard.sh` execute on every tool call, and `statusline.sh` re-renders
continuously. Each `jq` is a fork. A compiled binary is not merely tidier here,
it is faster than what runs today.

`specutil` already ships as a compiled binary on this machine, so the packaging
pattern is proven.

## What Changes

- A new Go module in this repository producing one multi-call binary,
  `sysinit-agent`, with a subcommand per migrated script.
- Tier A migrated first: `diffnote` and `citelock`, the two JSON state machines.
- Tier B migrated second: `agent-state`, `statusline`, `bash-guard`, and
  `exit-code-guard`, the four hot-path scripts.
- Every current command name is preserved by a thin `writeShellApplication`
  shim that execs the corresponding subcommand, so no caller, hook entry, or
  skill changes.
- The existing `checks/` derivations stay as the migration safety net and are
  run against the Go implementation unchanged.

### Non-goals

- No migration of Tier C or D. `agent-sessions.sh`, `loop-gate.sh`,
  `worklog-query.sh`, and `agent-notify.sh` are candidates but are out of scope;
  `hack/update-*.sh`, `shell-prefix.sh`, and `agent-group.sh` orchestrate other
  binaries and stay in bash permanently.
- No change to any on-disk format. The diffnote store schema, the citations lock
  format, and the agent-state file-bus layout are unchanged, because the editor
  half (`lua/harness/diffnote.lua`) and the wezterm surfaces read them.
- No change to any command-line surface. Flags, subcommands, exit codes, and
  stdout/stderr split stay as they are.
- No new runtime dependency. The binary replaces `jq` in these paths; it does
  not add one.
- `wtrun.sh` is not migrated. It has real concurrency, but 90% of it is `exec`,
  so Go buys little.

## Behavior

Must do:
- `sysinit-agent diffnote` and `sysinit-agent citelock` pass the existing
  contract tests, decided by `nix flake check` with `checks/diffnote-roundtrip.nix`
  and `checks/citelock.nix` unmodified
- every migrated command remains callable under its current name, decided by
  `command -v diffnote citelock agent-state statusline` after a switch
- the diffnote store written by Go renders in the editor, decided by opening
  CodeDiff on a repo with notes and observing the virtual text
- a hot-path command runs faster than the script it replaces, decided by
  `hyperfine` comparing `agent-state` before and after
- no `jq` invocation remains in a migrated code path, decided by
  `rg 'jq ' modules/home/programs/llm/runtime/` returning no hit for a migrated
  script

Must still hold:
- the diffnote note-path derivation agrees between the writer and
  `lua/harness/diffnote.lua`, decided by `checks/diffnote-roundtrip.nix`
- concurrent writers do not lose a note, decided by a Go test spawning parallel
  `add` calls and asserting the final count
- a malformed or zero-byte store is refused rather than silently rebuilt,
  decided by a Go test asserting a non-zero exit and an untouched store
- note text is stripped of control bytes on the way in, decided by a Go test
  feeding control bytes and asserting the stored value
- `bash-guard` still denies the commands it denies today, decided by
  `checks/destructive-guard-fixtures.nix`

Human-owned decision:
- whether the added build step and Go module are worth the reduction in shell
  risk, since both tiers work today
- whether Tier C follows, once Tier A and B are in production use

## Impact

Modified code:
- `modules/home/programs/llm/runtime/`: six scripts replaced by shims
- `modules/home/programs/llm/runtime/default.nix`: packaging switches to
  `buildGoModule` plus shims
- `pkgs/sysinit-agent/`: new Go module
- `checks/`: unchanged, but now exercise the Go binary

Dependencies: adds a Go toolchain at build time; removes `jq` from the migrated
runtime paths

Impactful and irreversible actions:
- replacing `diffnote` while a note store exists on this machine. The store
  format is unchanged, so a rollback reads it fine, but a Go defect could
  corrupt a store the owner has notes in. Back the store up before the first
  switch that carries the Go `diffnote`.
- replacing `bash-guard` and `exit-code-guard`, which sit on the deny path. A
  regression there fails open, which is worse than failing closed. These land
  last and behind their fixture check.

Gating signal: build-then-switch, one tier at a time. Tier A ships and is used
for at least a day before Tier B starts. Each tier is a separate switch, so a
regression is bisectable to one tier.
