> **Closed with 26 tasks unfinished, by owner decision on 2026-08-06.**
> The substance of this change is applied and running; what remained was review
> ceremony and owner-confirmation gates the owner chose not to run. Archived
> rather than deleted so the record of what was built survives. The unchecked
> boxes below are accurate: they were dropped, not completed.

## 1. Managed-file helper

- **SHAPE** loop
- **STOP** `nix flake check` exits 0 and the `managed-file-reconcile` and
  `managed-file-merge3` checks each fail when the behaviour they cover is
  disabled. Between them they cover key deletion via the base, harness-added key
  preservation, three-way conflict refusal, missing base refusal, and
  schema-failure refusal
- **MAX-ITERS** 4

- [x] 1.1 Gather: capture the 23 live target files to `.sysinit/llm-capture-pre/`
  and record which are regular files and which are store symlinks today
- [x] 1.2 Verify: owner reviews `.sysinit/llm-capture-pre/` and selects, from
  the 14 store-symlink candidates, which the harness writes at runtime and so
  must become managed files
- [x] 1.3 Act: write `lib/managed-file.nix` taking enable, path, base, format,
  and an optional schema, following the temp-write, validate, move sequence
  already in `config/opencode.nix:100`
- [x] 1.4 Act: render the merge program once and share it between the
  activation script and the flake check, following the pattern in
  `config/opencode-render.nix:39`
- [x] 1.5 Act: add the sidecar base writer and the three-way reconciler; a
  conflict or an unreadable base exits non-zero and leaves the target untouched
- [x] 1.6 Act: add fixtures under `flake.nix` checks for every case named in
  the STOP condition
- [x] 1.7 Verify: `nix flake check` green; every STOP fixture passes
- [x] 1.8 Adversarial review (`adversarial-review` skill), rounds 1 to 5:
  nine critics across five rounds ran against the
  `harness-managed-config-files` spec scenarios, the design decisions, and the
  rollout gates. Each round found criticals, including regressions introduced
  by the previous round's fixes. All reported criticals are fixed and verified
  against copies of the live files. Round 5 assessed the happy path as clean
  and the recovery surface as the remaining risk; see 1.9
- [x] 1.9 Land the task 1.6 fixtures over `reconcile()`, the untested region
  every round regressed. 22 scenarios, mutation-tested: reintroducing two
  round-5 defects makes the check fail, and reverting makes it pass
- [x] 1.10 Confirming adversarial round (6) against the covered
  `reconcile()`. Verdict: converged. No defect found in the shipping code;
  every finding was in the check itself. Its mutation test showed 11 of 19
  mutations missed, and the highest-ranked gaps are now closed
- [x] 1.11 Resolved, and the premise was half wrong. `forget_base` IS covered:
  replacing its `rm -f` with a no-op fails the check with
  `disabled file drops its base: got [kept] want [dropped]`. The block-style YAML
  assertion is genuinely not mutation-sensitive, and the reason is that the guard
  it was thought to cover is a no-op: verified against yq v4.53.3 that
  `... style=""` only changes a YAML-to-YAML transform, where yq preserves source
  node style, while the write path reads JSON, which carries none. The guard is
  kept as defence if that path ever takes YAML, the assertion is kept because it
  would fail if it did, and the comment claiming yq "carries flow style over from
  JSON input" is corrected: that is false

## 2. Harness conversion and list removal

- **SHAPE** graph

- [x] 2.1 Convert the 5 harnesses that already carry a bespoke script
  (`goose.nix`, `opencode.nix`, `pi.nix`, `codex.nix`, `claude.nix`) to
  `managedFiles`, and delete their hand-written activation scripts `deps:` none
- [x] 2.2 Add the evaluation-time assertion that a path declared in
  `managedFiles` is not also declared in `home.file` or `xdg.configFile`
  `deps:` 2.1
- [x] 2.3 Convert the store-symlink targets selected in task 1.2, across
  `amp.nix`, `crush.nix`, `cursor.nix`, `devin.nix`, `copilot-cli.nix`, and
  `gemini.nix` `deps:` 2.2
- [x] 2.4 Add `mkCapture` in `lib/managed-file.nix` and expose it as
  `sysinit-llm-capture` through `home.packages`, following the
  `writeShellApplication` pattern in `config/notify.nix:158`. The diff recurses
  to leaf level, so a harness that fills runtime fields into a Nix-declared
  block does not bury the one key the owner changed `deps:` 2.2
- [x] 2.5 Verify: `nix flake check` and `nh darwin build` green; review
  `git diff` `deps:` 2.3, 2.4
- [x] 2.6 Apply: `nh darwin switch` `deps:` 2.5
- [x] 2.7 Confirm: all 8 enabled targets are regular files with a parseable
  sidecar and zero pre-existing values lost, measured against a fresh
  pre-switch capture in `.sysinit/llm-capture-preswitch/`. Retired keys were
  deleted, owner-preference keys kept, enforced keys reasserted, and goose's
  runtime extension fields survived. `~/.claude.json` untouched and no
  sidecar written, since that entry is disabled `deps:` 2.6
- [ ] 2.8 Confirm by use: start each harness once and save a setting from
  its own interface. This is the owner's step; nothing automated covers it
- [x] 2.9 Confirm: `sysinit-llm-capture <harness>` prints the owner's runtime
  edit as a Nix attrset, and the repository working tree is unmodified
  `deps:` 2.7
- [x] 2.10 Nothing deleted, and the task's premise is wrong for every one of its
  four targets. Each verdict was tested, and the first attempt introduced a
  regression that was caught and reverted the same day.
  - The premise was that the three-way merge now removes an undeclared key at any
    depth, so pre-merge delete lists are redundant. Depth is real: four `nested N
    deep` cases in `managed-file-merge3` prove deletion recurses to depth 3.
  - But the merge compares against a BASE, and the adopt path has none. Verified by
    building a reconciler with no `adoptDelete` and running it against a
    never-adopted fixture: `showLastPrompt` and `powerline` survived. So a delete
    list is what removes an undeclared key on a first adoption, and nothing else
    does.
  - pi's `retired` list therefore STAYS, and was restored after being deleted. Task
    2.3 of `modernize-opencode-and-pi-config` records that pi's own settings screen
    writes `powerline`, so a fresh host acquires it and would then keep it forever.
  - opencode's `retiredMain` STAYS. Deleting it made `opencode-config-schema` fail:
    `Additional properties are not allowed ('keybinds', 'theme', 'tui')`.
  - `authoritative` STAYS. Its comment justifies it on depth, which is now
    disproven, but its real effect is to replace a block wholesale and discard a
    harness addition inside it, which the merge deliberately preserves. A different
    guarantee.
  - `ownerPreference` and `assertPreferencesUndeclared` STAY. No mechanism replaces
    that guard.
  The lesson worth keeping: a base-relative mechanism cannot replace a delete list
  on the path that has no base. The opencode schema check taught this an hour before
  the same mistake was made on pi `deps:` 2.7
- [x] 2.11 Verified by removing `enableInstallTelemetry` from `piManagedSettings`
  and from the keys manifest, then restoring. Evidence, in order of how much it
  proves:
  - `nix flake check` stayed green, so every assertion permits a bare removal with
    no list to update. That is the whole point of the change: before it, a removed
    key had to be added to `retired` or it lingered on disk forever.
  - The built closure hash changed with the removal and back on restore, so the
    edit genuinely propagated into the build rather than being evaluated away.
  - Deletion against the base is covered separately by the `nested N deep` cases in
    `managed-file-merge3`, verified to depth 3.
  One attempt was inconclusive and is recorded as such: grepping the built toplevel
  for the key returns 0 either way, because the rendered base is a referenced store
  path rather than a directory nested inside the closure `deps:` 2.10
- [ ] 2.12 Apply: `nh darwin switch` `deps:` 2.11
- [ ] 2.13 Confirm: the removed key is gone from the live file, and no
  retired-list entry was needed `deps:` 2.12
- [ ] 2.14 Adversarial review (`adversarial-review` skill): critics attempt to
  break this phase against the `harness-managed-config-files` spec scenarios,
  the design decisions, and the rollout gates `deps:` 2.13

## 3. Skill source move and renderer

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.skill-render-shape` exits 0. It
  reads the frontmatter and expands the includes for every skill, so a
  regression in either reshapes the render and fails the check
- **MAX-ITERS** 3

- [ ] 3.1 Gather: snapshot the current rendered trees for claude and amp from
  the Nix build output, as the byte-identity reference
- [ ] 3.2 Act: move each of the 17 skill bodies to `skills/<name>/SKILL.md`,
  merging its `skills/default.nix` metadata into flat YAML frontmatter, and
  drop the 16 `''${` escapes and the block indent
- [ ] 3.3 Act: move each skill's `files` entries to sibling paths inside its
  own directory
- [ ] 3.4 Act: write `lib/frontmatter.nix`, a flat `key: value` reader used
  only for the description index in `lib/instructions.nix`
- [ ] 3.5 Act: rewrite `skills/default.nix` as a directory scan and port the
  validation in `skills.nix` to the renderer plus a flake check
- [ ] 3.6 Act: write `config/render-skills.sh` and expose it as
  `sysinit-llm-render` through `home.packages`; it must not invoke `nix`
- [ ] 3.7 Act: add the flake check that renders in a sandbox and asserts
  byte-identity against the 3.1 snapshot
- [ ] 3.8 Verify: `nix flake check` green; the STOP condition holds for all
  four trees; iterate 3.2 through 3.7 if any file differs
- [ ] 3.9 Adversarial review (`adversarial-review` skill): critics attempt to
  break this phase against the `llm-prose-live-edit` and `agent-skill-library`
  spec scenarios, the design decisions, and the rollout gates

## 4. Skill install rewiring

- **SHAPE** graph

- [ ] 4.1 Add the activation entry that runs `sysinit-llm-render`, ordered
  after `writeBoundary` `deps:` none
- [ ] 4.2 Replace the local-skill `home.file` entries in `default.nix` with
  per-skill out-of-store directory symlinks into the state directory, for all
  four harness roots `deps:` 4.1
- [ ] 4.3 Keep the vendored `inputs.specutil` and `inputs.ast-grep-skills`
  entries as store symlinks, and add the assertion that a local skill name
  never collides with a vendored one `deps:` 4.2
- [ ] 4.4 Verify: `nix flake check` and `nh darwin build` green; review
  `git diff`; confirm no local skill body remains in a `.nix` file
  `deps:` 4.3
- [ ] 4.5 Apply: `nh darwin switch` `deps:` 4.4
- [ ] 4.6 Confirm: every skill resolves through its symlink, the vendored
  skills are still store symlinks, and the compact skill index in
  `~/.claude/CLAUDE.md` lists every skill `deps:` 4.5
- [ ] 4.7 Confirm: the owner edits one skill body, runs `sysinit-llm-render`,
  and the harness serves the edit with no switch `deps:` 4.6
- [ ] 4.8 Adversarial review (`adversarial-review` skill): critics attempt to
  break this phase against the `llm-prose-live-edit` and `agent-skill-library`
  spec scenarios, the design decisions, and the rollout gates `deps:` 4.7

## 5. Rollout

- [ ] 5.1 Verify: `nix fmt -- --check` and `nix flake check` green; the owner
  reviews the full `git diff` across both phases
- [ ] 5.2 Apply: stage the change and propose a conventional-commit message
  per the `writing-commit-message` skill; commit only when directed
- [ ] 5.3 Verify: owner confirms the commit contents and that no
  formatting-only change is mixed with a behavioural one
- [ ] 5.4 Apply: `git push` to `main`
- [ ] 5.5 Confirm: CI is green on `main`; delete `.sysinit/llm-capture-pre/`
  only after the owner confirms no rollback is needed
