## Context

`modules/home/programs/llm/` grew one directory at a time. Today it holds:

- `default.nix`, the aggregator, plus `options.nix`, `mcp.nix`, `skills.nix`, and
  `openspec-schema.nix` at the top level.
- `lib/`, nine pure evaluation helpers behind `lib/default.nix`.
- `skills/`, the scanned skill registry. A skill is a directory holding
  `SKILL.md`, and `skills/default.nix` walks its subdirectories to pick up
  `references/` and `scripts/` assets.
- `subagents/`, five teammate definitions behind `subagents/default.nix`.
- `citation-tools/`, one script and the module that installs it.
- `config/`, 46 files with no organizing rule.

Two established patterns are being extended rather than invented.

The first is `skills/<name>/`: a unit that owns its assets in its own directory.
`skills/worklog/scripts/worklog-query.sh` and
`skills/adversarial-review/references/adversarial-review-methodology.md` already
work this way, and `skills/default.nix` already installs them. A harness gets the
same shape.

The second is the aggregating `imports` list in
`modules/home/programs/llm/default.nix`. `harnesses/default.nix` reproduces it
one level down, so the top-level aggregator imports one directory instead of
eleven files.

Two constraints shape the work.

`config/notify.nix` is not a Home Manager module. It is a function that takes
`{ pkgs, lib }` and returns derivations plus paths. `flake.nix` imports it
directly for two checks. It keeps that calling convention as `runtime/default.nix`,
which matches how `lib/` and `skills/` are already imported.

`lib/guards.nix` reads `../config/claude-bash-guard.sh`. The evaluation library
reaching into the harness directory is backwards, and the file is shared by three
harnesses despite its name. Moving the body to `runtime/bash-guard.sh` removes both
problems in one edit.

## Goals / Non-Goals

Goals:

- The path names the owner. A file under `harnesses/pi/` is pi's, and a file
  under `runtime/` is nobody's in particular.
- A skill's tool script sits in the skill's directory.
- No top-level file shadows a directory of the same name.
- `lib/` reads no path inside the harness layer. It may still import sibling
  module trees, and does: `instructions.nix` needs `../subagents`, and
  `harness-kit.nix` is the aggregator, so it imports the renderer and the MCP
  catalog by design. The invariant is directional, not total.
- The devin and gemini exec guards block again, with a check that fails if they
  regress.

Non-Goals:

- Any change to generated output. This is a source move.
- Splitting `harnesses/pi/default.nix` by concern.
- Reorganizing `lib/` beyond moving `mcp.nix` in.
- Rewriting the task text of the seven in-flight changes that name old paths.
- A compatibility shim for the old paths. A single-user repository has no
  external consumer to keep working.

## Decisions

### D1. `runtime/` and `harnesses/`, not one directory with a naming convention

The split is by owner, because that is the question the reader has. A file is
either one harness's, or it is the agent-agnostic runtime every harness's hooks
call. Those two sets have different change patterns: a harness file changes when
that harness ships a release, and a `runtime/` file changes when the notification
or state contract changes.

The name `runtime/` contrasts with `lib/`. `lib/` runs at evaluation time and
produces values. `runtime/` is what a harness hook executes while an agent runs.

- Alternative rejected: keep one directory and encode the owner in the filename,
  which is what `pi-shell-prefix.sh` and `claude-bash-guard.sh` do today.
  Rejected because the convention is unenforceable, and it already produced a
  wrong name: `claude-bash-guard.sh` is shared by three harnesses and
  `devin-guard.sh` is shared by two.
- Alternative rejected: name the directory `shared/`, which was the first choice.
  Rejected because `skills/_shared/` already means something else, namely prose
  fragments included by more than one skill. Two directories named for sharing,
  holding different kinds of thing, is the naming failure this change exists to
  remove.

### D2. A harness gets a directory only when it owns an asset

`amp`, `codex`, `copilot-cli`, `crush`, `devin`, and `goose` stay single files.
`claude`, `cursor`, `gemini`, `opencode`, and `pi` become directories.

- Alternative rejected: give every harness a directory with a lone `default.nix`,
  so the relative import depth is uniform at `../../lib`. Rejected because it
  adds six directories that hold one file each, and it buys only the cosmetic
  benefit of one consistent import string.

### D3. A script belongs to a skill when the skill is its only consumer

`citelock.sh` and `wtrun.sh` meet the test. The `citation-verification` and
`wtrun` skills are their documentation, and no harness hook calls either. The
`agent-*.sh` scripts, `loop-gate.sh`, and `sy-gate.sh` fail the test: harness
hooks, the wezterm statusline, and the seshy integration all call them, so no
skill owns them.

- Alternative rejected: move every script that any skill mentions under that
  skill, which would put `sy-gate.sh` under `feature-based-session-manager` and
  `loop-gate.sh` under `specutil`. Rejected because both are called from wiring
  no skill controls, so the ownership claim would be false and the next reader
  would look in the wrong place for the caller.

### D4. A skill's tool script sits at the skill directory's top level

`skills/default.nix` installs the contents of a skill's subdirectories and
ignores files at the skill's top level. Putting `citelock.sh` at
`skills/citation-verification/citelock.sh` therefore colocates the source without
shipping a second copy into `.claude/skills/`, where it would compete with the
`citelock` already on PATH.

- Alternative rejected: `skills/citation-verification/scripts/citelock.sh`, which
  matches `skills/worklog/scripts/`. Rejected because `scripts/` is installed, so
  the agent would see two ways to run the same tool and one of them would bypass
  the PATH wrapper. `worklog-query.sh` belongs in `scripts/` for the opposite
  reason: it is invoked by path and is not on PATH.

### D5. One module owns the skill-owned CLIs

`skill-tools.nix` builds `citelock` and `wtrun` and puts both in `home.packages`.
A skill directory stays declarative content with no Nix in it, except
`skills/skills-ecosystem-discovery.nix`, which is already an exception for
vendoring reasons.

- Alternative rejected: a per-skill `package.nix` discovered by
  `skills/default.nix`. Rejected because that file returns the registry itself,
  and `skills/render.nix` maps over every attribute in it. A `packages` attribute
  would be rendered as a skill named `packages`, so the discovery would need a
  second scan and a second return shape for two scripts.

### D6. The guard receives an absolute path, not a name

`runtime/exit-code-guard.sh` reads `$GUARD_EXE`, injected at build time. The
current bare-name call is why the guard is dead: the name on PATH is
`devin-bash-guard` or `gemini-bash-guard`, never `claude-bash-guard`.

- Alternative rejected: rename every harness's guard derivation to
  `claude-bash-guard` so the existing call resolves. Rejected because three
  derivations sharing one name in `runtimeInputs` is the same latent collision in
  a new place, and the name would still claim one harness owns a shared guard.

### D7. The guard fix ships with a check, and ships last

The fix is the one phase that changes behavior, so it is separated from the moves
and lands after them. A flake check drives both wrappers with hook JSON and
asserts a block for a destructive command and a pass for an allowed one.

- Alternative rejected: fix the call during the `runtime/` move, since the file is
  already being touched. Rejected because it would put a behavior change inside a
  rename commit, where `git diff -M` would stop reporting a clean move and the
  review would have to separate the two by hand.

### D8. `harnesses/` holds harnesses, so the two cross-harness modules go to the root

`config/acp.nix` writes one shared ACP registry, and `config/mcp-servers.nix` sets
`sysinit.llm.mcp.additionalServers`. Neither configures a harness. Both move to
the module root, where `mcp-servers.nix` lands beside the `options.nix` that
declares the option it sets. The root then holds only cross-harness modules:
`default.nix`, `options.nix`, `acp.nix`, `mcp-servers.nix`, `skill-tools.nix`, and
`openspec-schema.nix`.

- Alternative rejected: put both in `harnesses/` as harness-layer modules, which
  is where the layout sketch first placed them. Rejected because a directory whose
  rule is "one module per harness" stops being a rule the moment it holds two
  modules that are not harnesses, and the reader then has to check each file to
  learn which kind it is.

## Rollout & Gating

Five build-verifiable phases, then rollout. Each phase ends with
`nix flake check` exiting 0, so each is independently landable and revertible.

1. Skill-owned tool scripts. Moves `citelock.sh` and `wtrun.sh`, adds
   `skill-tools.nix`, deletes `citation-tools/`. Gate: `nix flake check`, which
   includes the citation gate that runs the moved script.
2. Agent runtime. Creates `runtime/`, moves the nine `agent-*.sh` scripts,
   both gates, both guard bodies, and `notify.nix`. Repoints `lib/guards.nix` and
   the two `flake.nix` checks that source these scripts by path. Gate:
   `nix flake check`.
3. Harness layer. Creates `harnesses/` with `default.nix`, moves all eleven
   harness modules and their assets, deletes `config/`. Gate: `nix flake check`.
4. Eval-library and renderer paths. Moves `mcp.nix` to `lib/mcp-catalog.nix` and
   `skills.nix` to `skills/render.nix`. Gate: `nix flake check`.
5. Guard fail-open fix. Injects `$GUARD_EXE`, renames gemini's wrapper
   derivation, adds the new check. Gate: the new check fails against the
   pre-fix script and passes against the fixed one.
6. Rollout. `nh darwin build`, `diff -r` against the current generation, then
   `nh darwin switch`.

The gate sequence is the repository default: edit, `nix flake check`,
`nh darwin build`, owner spot-check, `nh darwin switch`. There is no feature flag,
because a source move has no runtime toggle. The kill switch is `git revert` of
the phase commit.

## Risks / Trade-offs

- A moved file silently stops being installed, because `home.file` is built from
  `lib/mapAttrs'` over a scanned directory and a missing source is a different
  attribute rather than an error. Mitigation: Rollout compares the built
  generation against the current one with `diff -r`, which names any file that
  appears or disappears. This is the phase-6 owner gate.
- A `flake.nix` check keeps passing for the wrong reason after a path edit,
  because it greps a file that moved and finds nothing. Mitigation: the shellcheck
  check already carries `require_nonempty` canaries for exactly this failure. The
  canary moves from `llm/config` to `llm/runtime` and gains `llm/harnesses`.
- The guard fix could over-block, denying commands the owner expects to run.
  Mitigation: the new check asserts exit 0 for an allowed command as well as a
  non-zero exit for a destructive one. This risk is the reason phase 5 is separate
  and last.
- Seven in-flight changes name the old paths in their task text, so their tasks
  read against a tree that no longer matches. Mitigation: the path map is recorded
  in the Rollout phase. Rewriting seven changes' artifacts is a larger and
  riskier edit than leaving one map to read them against.
- `git diff` for phases 2 and 3 is large, so a real edit could hide among the
  renames. Mitigation: each phase separates pure moves from reference updates into
  distinct tasks, and `git diff -M --stat` is read per task rather than per phase.

## Migration Plan

There is no state to migrate. Every step is a source edit verified by a command,
followed by one applied step at the end.

1. Phases 1 through 5, in order. Each is `git mv` plus reference updates, then
   `nix flake check`. Reverting any phase is `git revert` of its commit.
2. Verify before applying: `nh darwin build`. This writes no system change.
3. Confirm before applying: `diff -r` the previous generation's result path
   against the new one. The owner reads the file list and decides whether every
   difference was intended.
4. Apply: `nh darwin switch`, gated on step 2 exiting 0 and step 3 being
   confirmed.
5. Confirm after applying: the owner runs `citelock verify`, `wtrun --status`, and
   one agent session, then reports whether the notifier and statusline still fire.

Rollback: `git revert` the phase commit, then `nh darwin switch`. No file outside
the repository is rewritten by any phase, so the revert is complete.

## Adversarial Review

The rubric is the proposal's `Behavior` criteria, the `Decisions` above, the
`Rollout & Gating` gates, and the proposal's `Non-goals`.

Two halves, per the `adversarial-review` skill. The deterministic
`specutil check` lint is mandatory and runs on every phase. The LLM critic loop
is default-on and owner-gated: the skill elicits approve or deny, and a waiver is
recorded as `Adversarial review: waived by owner`. When it runs, independent
critics attempt to break the phase with a concrete failing scenario naming a
violated rubric item, the author revises against surviving objections, and the
loop repeats to a terminal state. The skill scales the round cap and stops early
on non-convergence or fix-induced churn. A cap hit is reported as open
objections, never as a pass. Do not re-derive the methodology here; the skill
carries it.

## Open Questions

- `harnesses/pi/default.nix` stays 761 lines, which is longer than the other ten
  harness modules combined. Splitting it is a separate change, and this one gives
  it a directory to be split into.
- `lib/mcp.nix` and `lib/mcp-catalog.nix` sit side by side as the formatters and
  the catalog. The pairing is clearer than a top-level `mcp.nix`, but the two
  names still have to be read to tell apart. Rename `lib/mcp.nix` to
  `lib/mcp-format.nix` if that ambiguity costs anything in practice.
