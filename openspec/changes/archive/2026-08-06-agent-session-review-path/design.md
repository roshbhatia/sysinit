## Context

Everything this change needs already exists and is not joined up.

- `modules/home/programs/llm/config/agent-state.sh:120` writes a per-pane JSON
  file carrying `session`, `repo`, `branch`, `dirty`, `worktree`, `status`, and
  `since`.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua:187` prunes those files
  against the live pane set, which is the liveness rule this change restates.
- `modules/home/programs/seshy/config.yaml` is Nix-managed and already carries a
  `postCreate` hook. `sy config` shows `preDelete` is an accepted key with an
  empty list today.
- `sy delete` exists with a documented `--force` flag.

Patterns reused: `agent-focus.sh:24` already reads the per-pane state file, so
the report follows an existing reader rather than inventing a second shape. The
`postCreate` entries in `config.yaml` are the shape for the new `preDelete`
entry.

No new pattern is introduced, and no new package: `git`, `jq`, and `wezterm` are
already runtime inputs of the notifier scripts.

## Goals / Non-Goals

Goals:

- Answer "is this session finished?" from data that is free to read.
- Make `sy delete` refuse to discard unfinished work, without ever writing.
- State the liveness rule once, so a second reader cannot disagree with the
  statusline.

Non-goals:

- Merging, pushing, or opening a pull request.
- Running a build or a test suite on an interactive command's path.
- Changing the seshy binary. This is its config plus one script here.
- A graphical workspace list.

## Decisions

### D1. Readiness is git state plus agent state, and nothing else

Both are local reads that cost milliseconds. A build or a test run would make
`sy delete` unpredictable and would tempt the owner to reach for `--force`
habitually, which destroys the gate's value.

- Alternative rejected: run the repository's own check command, the way
  Conductor surfaces per-workspace checks. Rejected because this gate sits on an
  interactive command; a multi-minute check there trains the owner to bypass it.

### D2. The gate only ever refuses

The report never commits, pushes, or stashes. Unfinished work is a decision, and
the tool that discovers it is the wrong place to make that decision.

- Alternative rejected: auto-commit or auto-stash before deleting. Rejected
  because it converts a visible refusal into a silent mutation of the owner's
  work, which is worse than the problem.

### D3. A broken report allows the deletion

If the report is missing or errors for a reason other than unfinished work, the
gate must not make a session undeletable. A gate that can trap a session is a
worse failure than a gate that occasionally misses.

- Alternative rejected: fail closed, refusing whenever readiness is unknown.
  Rejected because the only recovery would be `--force`, which is exactly the
  habit D1 is protecting.

### D4. Liveness is restated in the spec rather than reimplemented per reader

The report runs outside WezTerm's Lua and cannot call `ui.lua`'s pruning. Rather
than let each reader invent its own rule, the rule is written into
`agent-state-emission` so both readers cite one source.

- Alternative rejected: have the report shell out to the WezTerm CLI and
  reimplement pruning inline with no shared statement. Rejected because that is
  how the notification group string came to have three definitions.

## Rollout & Gating

Two phases.

1. The report command, installed and runnable by hand, with no hook wired. Gate:
   `nix flake check` and `nh darwin build` green, and the owner runs
   `agent-review` against a real session and agrees with its verdict.
2. The `preDelete` hook. Gate: the owner confirms `sy delete` refuses an
   unfinished session, that `--force` still deletes, and that a finished session
   deletes with no extra prompt.

Default sequence: edit, `nix flake check`, `nh darwin build`, owner spot-check,
`nh darwin switch`. No deviation.

Kill switch: remove the `preDelete` entry from `config.yaml` and switch. The
report command stays installed and harmless.

## Risks / Trade-offs

- The gate makes a routine command stricter, so a false positive is annoying at
  exactly the wrong moment. Mitigation: `--force` is documented in the refusal
  message itself, and D3 makes an unknown verdict permissive.
- The report reads a bus whose schema `harden-agent-shell-terminal` is
  versioning. Mitigation: it tolerates a file with no version field, because
  that change has not landed. Flagged for recheck when it does.
- A session with many repositories runs one `git status` per repository.
  Mitigation: these are local reads on an interactive path the owner already
  waits on; if it ever matters, the per-repository loop is the place to cap.
- `sy delete` may invoke the hook with a cwd this change does not control.
  Mitigation: phase 1 confirms the hook's cwd and arguments against the real
  binary before phase 2 wires it.

## Migration Plan

1. Verify: `nix flake check` passes before any edit.
2. Apply phase 1 and switch. Confirm: `agent-review` on a real session matches
   what `git status` says in each repository.
3. Verify: the owner confirms the hook contract, meaning cwd and session name,
   against the installed seshy. Apply phase 2 and switch.
4. Confirm: an unfinished session refuses, `--force` deletes, a finished session
   deletes cleanly.

Rollback: remove the `preDelete` entry and switch.

## Adversarial Review

Rubric: the spec scenarios in this change including every negative one, the
Decisions above, the Rollout & Gating phase gates, and the proposal Non-goals.

The deterministic half is mandatory: `specutil check` runs on every phase.

The critic half is default-on and owner-gated per the `adversarial-review`
skill. The round cap is K=4 for this single-capability change, and the loop also
stops early on non-convergence or fix-induced churn. A cap hit is reported as
open objections, never as a pass.

### D5. seshy is a flake input, so the gate execs a known store path

seshy now ships a flake, so `pkgs.seshy` exists and the gate bakes its absolute
store path at build time. Two earlier resolution strategies are gone: scanning
PATH while excluding `/nix/store`, which would have broken the moment seshy
became Nix-managed, and scanning while skipping itself, which depended on
resolving its own path correctly.

seshy is deliberately NOT in `home.packages`. The gate is the only thing that
installs a binary named `sy`, and two packages providing `bin/sy` would collide
in one profile.

- Alternative rejected: install seshy normally and give the gate a different
  name, such as `sy-guarded`, with a shell alias. Rejected because an alias is
  not read by `zsh -c`, by scripts, or by an agent's shell tool, which is the
  exact bypass that moved this gate out of `.zshrc` in the first place.

## Open Questions

- Answered in phase 1. seshy passes the hook environment variables, confirmed
  by a string scan of the installed binary: `SESHY_EVENT`, `SESHY_SESSION`,
  `SESHY_SESSION_PATH`, `SESHY_REPOS`, and `SESHY_REPO_COUNT`. The report reads
  `SESHY_SESSION_PATH` and falls back to the cwd.
- Should the report also surface on the statusline, so a session reads as ready
  before the owner types `sy delete`? Deferred; it needs a surface decision.
