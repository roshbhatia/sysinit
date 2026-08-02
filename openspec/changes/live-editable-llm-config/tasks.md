## 1. Managed-file helper

- **SHAPE** loop
- **STOP** `lib/managed-file.nix` passes fixtures for JSON, YAML, and TOML
  covering: key deletion via the base, harness-added key preservation,
  three-way conflict refusal, missing base refusal, and schema-failure refusal
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
- [ ] 1.11 Two assertions remain unverified by mutation: `forget_base`
  removing a disabled file's base, and the block-style YAML guard. Both pass
  today and both still pass with the behaviour disabled, so neither is
  currently proving anything. Close before relying on them

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
- [ ] 2.7a Confirm by use: start each harness once and save a setting from
  its own interface. This is the owner's step; nothing automated covers it
- [x] 2.8 Confirm: `sysinit-llm-capture <harness>` prints the owner's runtime
  edit as a Nix attrset, and the repository working tree is unmodified
  `deps:` 2.7
- [ ] 2.9 Delete the `retired` and `authoritative` lists in
  `config/opencode-render.nix` and the `retired` and `ownerPreference` lists
  plus their five assertions in `config/pi.nix` and
  `config/pi-settings-keys.nix` `deps:` 2.7
- [ ] 2.10 Verify: remove one key from a harness config in Nix;
  `nh darwin build` green `deps:` 2.9
- [ ] 2.11 Apply: `nh darwin switch` `deps:` 2.10
- [ ] 2.12 Confirm: the removed key is gone from the live file, and no
  retired-list entry was needed `deps:` 2.11
- [ ] 2.13 Adversarial review (`adversarial-review` skill): critics attempt to
  break this phase against the `harness-managed-config-files` spec scenarios,
  the design decisions, and the rollout gates `deps:` 2.12

## 3. Skill source move and renderer

- **SHAPE** loop
- **STOP** the sandbox render of all four harness trees is byte-identical to
  the tree the current Nix path produces, for all 17 skills
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
