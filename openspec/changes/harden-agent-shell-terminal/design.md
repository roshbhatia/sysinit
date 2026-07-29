## Context

Three surfaces carry the daily-driver configuration for this machine:

- Agent: `modules/home/programs/llm/`, about 4,900 lines across 9 harness
  configs, 5 hook scripts, 4 subagents, and the state bus.
- Shell: `modules/home/programs/zsh/`, about 470 lines of Nix and zsh
  fragments plus 5 pinned plugins.
- Terminal: `modules/home/programs/wezterm/`, about 3,200 lines of Lua plus 10
  plugins, two of which carry local patches.

`flake.nix:217` defines the `checks` output. It holds three entries:
`openspec-default-schema`, `schema-templates-conform`, and `citelock`. All
three guard the OpenSpec workflow. None touches the three surfaces above.

`.github/workflows/` holds three workflows: `build-cache`, `update-sources`,
and `auto-merge-dependabot`. None runs `nix flake check`. `build-cache` builds
`packages.<system>.cacheBundle` and triggers only on `flake.lock`, `flake.nix`,
`overlays/**`, `_sources/**`, and `nvfetcher.toml`. A change under `modules/`
never gets built by CI.

`.githooks/pre-commit` runs `citelock` and nothing else.

`shellcheck` and `stylua` are installed in `modules/home/packages.nix` at lines
72 and 117. Nothing runs either one. Every `.zsh` fragment carries
`# shellcheck disable=all`. `AGENTS.md` documents `task fmt:sh` and
`task fmt:sh:check` and no Taskfile exists in the repository. `flake.nix`
defines no `devShells`.

Existing patterns this change extends rather than parallels:

- `flake.nix:229` is the check shape: a hermetic `pkgs.runCommand` with `HOME`
  and `XDG_DATA_HOME` in the build tmp, no network, a clear pass line to
  `$out`, and a failure that names what broke and how to fix it. Every new
  check follows it.
- `modules/darwin/keybindings.nix:151` is the chord model: modifier bits and
  key codes canonicalized to a `mods+key` string, then compared across layers
  by eval-time assertion. WezTerm joins that model. `mkChord`, `keyAliases`,
  and `canonicalKey` are extended, not duplicated.
- `modules/home/programs/wezterm/default.nix:130` is the Nix-to-Lua transport:
  values rendered into `wezterm/config.json`, read back by
  `plugin_loader.lua:9` through `utils.load_json_file`. The chord list joins
  that file rather than gaining a new one.
- `modules/home/programs/llm/lib/allowlist.nix:325` is the registry shape: one
  canonical list, a formatter per consumer. The guard scripts become one more
  consumer.
- `modules/home/programs/llm/config/notify.nix:77` is the operator-script
  shape: a `writeShellApplication` in `home.packages` with the shared identity
  resolver prepended. `sysinit doctor` follows it.

No new pattern is introduced by this change.

## Goals / Non-Goals

Goals:

- Every authored fragment fails at build time when it does not parse.
- Every check runs on every change without the owner remembering to run it.
- A failure in one WezTerm module costs that module and nothing else.
- Every keybinding layer on the machine is visible to one collision check.
- The agent state bus has a stated contract that a build can verify.
- Runtime drift is observable through one command.
- The guard scripts and the shared pattern list cannot disagree.

Non-Goals:

- Changing the permission model. `dangerouslySkipPermissions = true` and
  `sandbox.enabled = false` stay. The owner has confirmed that explicit guards
  are the intended design.
- Widening or narrowing the deny set.
- Replacing regex command matching with a parsed shell grammar.
- Gating any branch other than `main`, or requiring any check other than the
  new `verify` job.
- Restructuring `ui.lua`.
- Managing the shell escape hatches. The doctor reports them and stops there.
- Auditing third-party WezTerm plugins.

## Decisions

- Decision: parse Lua with a standalone Lua front end rather than by loading
  the files. The modules call `require("wezterm")` at the top, which only
  resolves inside the WezTerm host, so loading is not possible in a sandbox.
  Syntax checking catches the class this change is aimed at: the typo that
  ships green.
  - Alternative rejected: run `wezterm --config-file` in the check. It needs a
    GUI-capable host, is not hermetic, and would make the check platform-bound
    when the checks already run for three systems.

- Decision: extract the WezTerm chords by loading `keybindings.lua` under a
  stubbed `wezterm` inside a check, and compare them there. Nix cannot run Lua
  at evaluation time, but a check can, so the chords never have to be mirrored
  into Nix at all.
  - Alternative rejected: declare the chord half of each binding in Nix and have
    Lua read it back, as originally planned. Measurement killed it. Other layers
    own only 10 chords in total (7 reserved, 3 enabled symbolic hotkeys), and
    WezTerm uses ALT in 0 of its 86 chords while aerospace uses ALT in all 26,
    so the two cannot collide. Restructuring 7 binding groups and ~90 entries to
    protect a 10-chord surface risks a transcription error in keys used daily,
    and it recreates the mirror-drift problem this change exists to remove.
  - Alternative rejected: commit a generated chord manifest for Nix to read.
    That is the hand-maintained mirror again, just generated once.
  - Cost accepted: the collision now fails at `nix flake check` rather than at
    `nh darwin build`. Both run before a switch and CI runs the former.

- Decision: prevent aerospace collisions by invariant rather than comparison.
  The check asserts WezTerm binds no ALT chord; aerospace binds only ALT chords.
  - Alternative rejected: enumerate aerospace's bindings and compare. They live
    in module config that a check cannot import without evaluating a host
    configuration, and the invariant is both cheaper and stronger: it fails the
    moment WezTerm reaches into aerospace's space, not only on an exact clash.

- Decision: record `cmd+m` as an accepted overlap rather than resolving it.
  Symbolic hotkey ID 233 is enabled as `cmd+m` and WezTerm binds `SUPER+m` to
  `Hide`. ID 233 carries no label and sits among IDs captured from the machine's
  own defaults, so it is most likely a preserved macOS default. The overlap is
  recorded in the check with its reason and stays visible.
  - Alternative rejected: disable hotkey 233, or move WezTerm's `Hide` binding.
    Both change live behaviour to resolve an overlap whose actual effect is
    unknown, which is a worse trade than documenting it until ID 233 is
    identified.

Measured fallback behaviour (task 3.1, previously an assumption):

A copy of the generated config tree was loaded through a real `wezterm` binary
with `--config-file`, with `error()` injected at the top of `ui.setup`.

| Config | key-table lines | `action_callback` bindings |
|---|---|---|
| working | 230 | 96 |
| `ui.lua` raises at runtime | 274 | 0 |
| not valid Lua at all | 274 | 0 |

The last two outputs are byte-identical. A runtime error anywhere in the module
chain therefore discards the entire config table and WezTerm falls back to its
built-in defaults. All 96 custom bindings go. `core.setup` writes into that same
discarded table, so `default_prog`, `PATH`, `SHELL`, and `TERM` go with them: a
`ui.lua` typo costs the owner their Nix zsh and their whole environment. The
assumption in the proposal is confirmed, and the cost is larger than stated.

- Decision: keep `core.setup` outside the `pcall`. It sets `default_prog`,
  `PATH`, and `SHELL`. Catching a failure there would produce a terminal that
  starts the wrong shell with the wrong environment, which is worse than a
  loud configuration error.
  - Alternative rejected: wrap all four modules uniformly. Uniformity is
    cheaper to write and hides the one failure that must not be survivable.

- Decision: generate the guard script's pattern list from
  `destructiveDenyRegexes` at build time, by interpolating the list into the
  script text the way `claude.nix:95` already interpolates the Slack channel
  case arms.
  - Alternative rejected: have the script read the pattern list from a JSON
    file at runtime. It adds a read and a parse to a hot fail-open path, and a
    missing file would silently disable the guard.

- Decision: reconcile the five drifted guard patterns toward the guard's `-f`
  form and the shared list's `\b` forms. The guard anchored `-f` on leading
  whitespace and its comment recorded that as deliberate, so the looser form is
  the intentional one: without the anchor, `git push origin feature-f` is denied.
  The four `\b` versus `[[:space:]]` differences went the other way, to the
  shared list's `\b`, which matches marginally more with no false positive found.
  A fixture locks each direction, including `git push origin feature-f` as an
  allowed form.
  - Alternative rejected: apply "stricter always wins" mechanically. It would
    have adopted the unanchored `-f` and started denying legitimate pushes to any
    branch whose name ends in `-f`.

- Decision: generate the guard's pattern table from `destructiveDenyRules` via
  `lib/guards.nix`, and have the fixtures exercise the assembled script rather
  than the source file. Once the patterns arrive by preamble, the bare file
  denies nothing, so testing it would prove nothing.
  - Alternative rejected: keep testing `claude-bash-guard.sh` directly. That is
    the same mistake as parsing fragment files while the real content lives
    somewhere else, which is what the first round of review caught.

- Decision: give the state file an integer version field and validate the
  emitter's output against a JSON schema in a check.
  - Alternative rejected: document the shape in the spec only. That is what
    exists today, and it is what let five consumers depend on a comment.

- Decision: collect stale state entries in one place rather than per harness.
  A per-harness exit hook needs 9 wirings and still misses a crashed session.
  - Alternative rejected: keep the current arrangement, where each reader
    prunes by liveness. It puts the same logic in five repositories and a
    reader that forgets it shows dead sessions.

- Decision: make `sysinit doctor` report and exit non-zero rather than repair.
  Its probes cover owner-managed state, and a tool that edits `~/.zshenv` or
  deletes cache entries on its own is a surprise.
  - Alternative rejected: an auto-repair mode. It would need its own guard
    rails, and the repair for every probe found here is a single command the
    owner can run.

- Decision: run the new CI job on push to `main` and on every pull request,
  with no path filter.
  - Alternative rejected: filter by path the way `build-cache` does. The gap
    this change closes is exactly the `modules/` path that filter skips.

- Decision: CI evaluates the host configuration rather than building it. Forcing
  `.drvPath` evaluates the whole module tree, which is what fires the
  assertions, in about 10 seconds while materialising nothing. Verified by
  injecting a failing assertion: the eval aborts with its message.
  - Alternative rejected: `nix build` of `darwinConfigurations.lv426.system`.
    Measured at 17.9 GiB closure against roughly 14 GB free on a `macos-latest`
    runner, so it fails on disk before it can fail on anything useful.

- Decision: keep the authored shell and Lua in files, not in Nix string
  literals. The parse checks glob by extension, so a fragment inlined into a Nix
  string is invisible to them. `zsh/default.nix` kept about 30 lines of zsh and
  `wezterm/default.nix` about 20 lines of Lua inline; both moved out to
  `core/compinit.zsh` and `sysinit/pkg/bootstrap.lua`. Coverage then holds by
  construction rather than by a rule someone has to remember.
  - Alternative rejected: teach the checks to evaluate the assembled
    `initContent` and `extraConfig` and parse the result. It reaches into
    home-manager evaluation from inside a check derivation, and it leaves the
    inline code as the only shell in the repo that no file check covers.

- Decision: the shellcheck check scans the whole flake source and selects by
  shebang as well as by extension.
  - Alternative rejected: scan a list of directories. The list is itself the
    escape hatch. The first revision scanned `llm/config` and `hack/`, and
    silently missed `citation-tools/citelock.sh`,
    `skills/scripts/worklog-query.sh`, and the extensionless
    `.githooks/pre-commit`.

- Decision: switch the Dependabot auto-merge to `--auto --squash` and require
  the `verify` job on `main`.
  - Alternative rejected: leave the auto-merge alone and record the bypass as a
    known limitation. It leaves the gate inert for exactly the changes that most
    need it, and `--auto` fails safe: without the repo settings the command
    errors rather than merging early.

- Decision: add `devShells.default` carrying `nh`, `shfmt`, `shellcheck`, `lua`,
  `jq`, and `fd`.
  - Alternative rejected: reword the requirement to exempt machine-wide tools.
    It would make the requirement true by weakening it, and `nh darwin build`
    would still not run on a fresh checkout.

## Rollout & Gating

Six slices. Each is independently reviewable and shippable. No slice depends on
a later one.

Slice 1 ships first and alone. Everything after it is only enforceable because
it exists.

```
  1. verification gate  ──▶ checks exist and CI runs them
         │
         ├──▶ 2. guard fixtures        (needs 1 to be enforced)
         ├──▶ 3. wezterm containment   (needs 1 for the Lua parse check)
         ├──▶ 4. chord registry        (needs 3 to be settled first)
         ├──▶ 5. state bus contract    (needs 1)
         └──▶ 6. sysinit doctor        (needs 5 for the bus probe)
```

Gate sequence per slice, the repository default:

1. Edit.
2. `nix flake check` green.
3. `nh darwin build` green.
4. Owner reviews `git diff`.
5. `nh darwin switch`.
6. Owner spot-checks the slice's own behavior.

Two slices add a gate beyond the default:

- Slice 2 lands the fixture check before the guard rewrite, inside the same
  slice. The fixtures must pass against the current inlined patterns first.
  Only then does the script switch to the generated list, and the fixtures must
  still pass. This makes the drift visible as a fixture diff rather than as a
  silent behavior change.
- Slice 3 adds a runtime gate. The owner injects a deliberate error into
  `ui.lua`, starts WezTerm, and records the observed behavior before and after
  the containment. The specification requires this because the fallback
  behavior is currently an assumption.

Kill switches:

- Slice 1: the CI job is a separate workflow file. Delete or disable it without
  touching any check.
- Slice 3: the `pcall` wrapper is one function in `default.nix`'s
  `extraConfig`. Reverting restores the current unguarded calls.
- Slice 4: the chord registry renders into the existing `config.json`.
  `keybindings.lua` falls back to its current inline table when the key is
  absent, so a revert of the Nix half leaves a working terminal.
- Slice 6: `sysinit doctor` is a new command. Nothing depends on it.

## Risks / Trade-offs

[The Lua parse check passes files that still fail at runtime] to Mitigation:
this is accepted and stated in the specification. Syntax checking catches the
typo class. Slice 3's containment covers the runtime class. The two are
complementary and neither replaces the other.

[Moving chords to Nix breaks a binding during the migration] to Mitigation:
migrate group by group. Each group's move is one commit, verified by the
duplicate-detection assertion plus an owner spot-check of that group's keys.
This is a human-verification checkpoint in `tasks.md`.

[The chord canonicalization mismaps a key and reports a false collision] to
Mitigation: an unmapped key name fails loudly rather than being treated as
unique. A false positive blocks a build and is visible. A false negative would
be silent and is the failure this change exists to prevent.

[Rewriting the guard to use generated patterns weakens the deny set] to
Mitigation: the fixture check lands first, in the same slice, and must pass
before and after the rewrite. This is a human-verification checkpoint in
`tasks.md`.

[The four drifted patterns mean the guard and the harnesses currently deny
different things] to Mitigation: the fixture table records the current behavior
of both, so the reconciliation is a reviewed decision rather than a side
effect. Where they differ, the stricter form wins, and the choice is recorded.

[Containment converts a loud failure into a quiet one] to Mitigation: the
specification requires a visible report through a channel that does not need a
log file to be opened. Silent degradation is called out as a defect.

[CI on every pull request slows the loop or costs runner minutes] to
Mitigation: the checks are small `runCommand` derivations and the host build is
cached through the existing Cachix setup. If the cost is real, the host build
moves to push-only and the checks stay on pull requests.

[`sysinit doctor` becomes a second source of truth about health] to Mitigation:
its probes cover runtime state only. Anything a build can check stays in
`checks`. The command explicitly does not re-implement a build check.

## Migration Plan

Each slice follows the same shape. The impactful action in every slice is
`nh darwin switch`, and slice 1 additionally adds a workflow file.

Slice 1, verification gate:

1. Verify: add the checks, run `nix flake check`, and confirm each new check
   both passes on the current tree and fails when a defect is injected.
2. Apply: commit the checks and the workflow file.
3. Confirm: the workflow runs on the next pull request and its result is
   visible. If the merge automation cannot merge a workflow change, the owner
   merges it manually. `AGENTS.md` no longer names a command that does not
   exist.

Slice 2, guard fixtures and pattern reconciliation:

1. Verify: fixtures pass against the current inlined patterns. Record which of
   the six patterns differ between the script and `destructiveDenyRegexes`.
2. Apply: switch the script to the generated list.
3. Confirm: fixtures still pass. The owner runs one denied form and one
   permitted form through a live agent session and observes the expected
   outcome.

Slice 3, WezTerm containment:

1. Verify: reproduce a Lua error in `ui.lua` on the current configuration and
   record the observed behavior. `nh darwin build` green.
2. Apply: `nh darwin switch`.
3. Confirm: reproduce the same error and observe that the shell, the
   environment, and the keybindings survive, and that the failure is reported.
   Remove the injected error and confirm normal startup.

Slice 4, chord registry:

1. Verify: `nix flake check` green with the assertion active. Inject a
   deliberate collision and confirm it fails. Inject a duplicate and confirm it
   fails.
2. Apply: `nh darwin switch`.
3. Confirm: the owner exercises one chord from each of the seven binding
   groups.

Slice 5, state bus contract:

1. Verify: the schema check passes for every reason source. `nh darwin build`
   green.
2. Apply: `nh darwin switch`.
3. Confirm: the statusline and the WezTerm session switcher both still render
   agent state for a live pane. A killed pane's entry is collected.

Slice 6, doctor:

1. Verify: the command runs on the current machine and every probe returns.
2. Apply: `nh darwin switch`.
3. Confirm: `sysinit doctor` exits zero on a clean machine and non-zero when
   the owner injects one drift.

Rollback for every slice is `git revert` followed by `nh darwin switch`.
Slice 1's rollback additionally removes the workflow file. No slice writes
state that a revert cannot undo. Slice 5 changes the state file shape, and old
files are collected rather than migrated, because they are per-session and
regenerate on the next agent turn.

## Adversarial Review

The rubric is:

- Every scenario in the six spec files, including the negative ones.
- The Decisions above, each of which must survive its recorded rejected
  alternative.
- The Rollout & Gating gates, in particular the two slices that add a gate
  beyond the default.
- The proposal's Non-goals, in particular the permission model, which is out of
  scope by owner decision.

The deterministic half is `specutil check`. It is mandatory and runs on every
slice.

The critic half is default-on and owner-gated. The `adversarial-review` skill
elicits an approve or deny per slice. On approve, independent critics attempt
to break the slice with a concrete failing scenario that names a violated
rubric item. The author revises against surviving objections. The loop repeats
until no objection survives or K equals 4 rounds. On deny, the checkbox records
`Adversarial review: waived by owner`.

Under Claude Code the critics run as in-process teammates, per
`settings.teammateMode = "in-process"` at `claude.nix:160`.

Slice 2 is the one to review hardest. It rewrites the only mechanical floor
under the agent's Bash tool while `dangerouslySkipPermissions` is on.

## Open Questions

- Which host does the CI job build? `lv426`, `arrakis`, and `nostromo` differ.
  Building the Darwin host on a macOS runner is the closest to the daily
  driver, and building a Linux host is cheaper. The current view is to build
  the Darwin host on `macos-latest` and reuse the existing Cachix setup.
- Does the visible failure signal in slice 3 use a WezTerm toast, the existing
  agent state bus, or the tab title? The bus is already a cross-surface
  transport, but it is keyed on a pane that may not exist yet at configuration
  time.
- Where does stale-entry collection run? A WezTerm startup hook sees the live
  pane set directly. A shell hook runs more often but has to ask WezTerm for
  the pane list. The specification requires that it removes nothing when the
  live set cannot be determined, which both satisfy.
- Where do the four drifted guard patterns reconcile? The stricter form wins by
  default, but `git clean -f` and `git branch -D` differ in whether they
  require whitespace after the subcommand, and the looser form may be
  intentional.
- Does `sysinit doctor` belong in this repository or alongside the other
  machine-wide tools such as `specutil` and `sy`? It reads sysinit-specific
  paths, so this repository is the current view.
