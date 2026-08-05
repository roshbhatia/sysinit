## 1. Stand up the directory

- **SHAPE** graph

- [x] 1.1 Record every check's `drvPath` before any edit, so each later move has an
      exact baseline to compare against (19 checks)
- [x] 1.2 Add `checks/default.nix` taking one attrset and returning the checks
      attrset, and have `flake.nix` call `import ./checks { ... }` (follows
      `modules/lib/default.nix` and `harnesses/default.nix`) `deps:` 1.1
- [x] 1.3 Keep the small shell helpers local. Their contracts differ, so a shared
      prelude adds a dependency without removing equivalent code `deps:` 1.2
- [x] 1.4 Move `agent-review-readiness` without extracting its shell. Confirm its
      `drvPath` is unchanged `deps:` 1.3
- [x] 1.5 Run `nix flake check`. Confirm `check-bodies-shellcheck` covers the
      evaluated shell for every lintable check `deps:` 1.4
- [x] 1.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      phase 1 within the whole-change loop against the proposal `Behavior` criteria
      and D2 and D4, verifying by derivation path rather than by reading the diff;
      record the terminal outcome here `deps:` 1.5. Result: CLEAN in fresh round 1

## 2. Move the rest

- **SHAPE** graph

- [x] 2.1 Move `managed-file-reconcile` (274 lines) and `managed-file-merge3` (81),
      which share a subject and a prelude `deps:` 1.5
- [x] 2.2 Move `notify-defect-regressions` (171 lines), which carries two roots
      (`$cfg` and `$harness`) and the `require_file` guards `deps:` 1.5
- [x] 2.3 Move `destructive-guard-fixtures` (118) and `exit-code-guard-blocks`,
      which share the guard subject `deps:` 1.5
- [x] 2.4 Move `wezterm-chord-collisions` (103) and `shell-scripts-shellcheck`
      (105). The latter must not exclude its own new siblings `deps:` 1.5
- [x] 2.5 Move `citelock` (82), `skill-render-shape` (66), `pi-settings-keys-exist`
      (69), and `opencode-config-schema` (62) `deps:` 1.5
- [x] 2.6 Move the remainder: `schema-templates-conform`, `zsh-fragments-parse`,
      `lua-parses`, `openspec-default-schema`, `pi-no-theme-writer`,
      `pi-shell-prefix-loads-aliases`, and `llm-asset-paths-resolve` `deps:` 1.5
- [x] 2.7 Confirm all 19 `drvPath` values still equal the 1.1 baseline. A single
      mismatch means that check's body changed and the move is wrong
      `deps:` 2.1, 2.2, 2.3, 2.4, 2.5, 2.6. Result: 18 of 19 identical.
      `shell-scripts-shellcheck` legitimately changed, because its `src` IS the
      flake source and the move added 19 files to it. Isolated and proven: holding
      content constant, every other check including `citelock` is identical
- [x] 2.8 Run `nix flake check`, and fix every shellcheck finding the newly-linted
      bodies surface. A finding that reveals a real defect is recorded separately
      rather than silenced; a benign one gets a targeted disable with a reason
      `deps:` 2.7
- [x] 2.9 Adversarial review (`adversarial-review` skill): critics attempt to break
      phase 2 within the whole-change loop against the proposal `Behavior` criteria,
      in particular whether any assertion changed polarity or any store path arrived
      differently; record the terminal outcome here `deps:` 2.8. Result: CLEAN in
      fresh round 1

## 3. Reduce flake.nix

- **SHAPE** graph

- [x] 3.1 Remove the emptied checks region from `flake.nix` and confirm the file is
      under 300 lines with no Nix string block longer than 10 lines `deps:` 2.8
- [x] 3.2 Remove the single-use `cacheBundleFor` helper. Build the bundle directly
      in the `packages` output `deps:` 3.1
- [x] 3.3 Fail `check-bodies-shellcheck` when its derivation filter returns no
      checks `deps:` 3.1
- [x] 3.4 Compare the staged tree with base commit `5ccc8771a`. Eighteen of 21
      derivations stay identical. `check-bodies-shellcheck` changes by design.
      `citelock` and `shell-scripts-shellcheck` scan the full source, so the new
      formatter and artifact edits change their source input. After normalizing
      only that source path, both build commands are identical `deps:` 3.2, 3.3
- [x] 3.5 Format each changed Nix file. Leave unrelated formatting drift untouched
      `deps:` 3.4
- [x] 3.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      phase 3 within the whole-change loop against the proposal `Behavior` criteria
      and `Non-goals`, in particular whether anything outside the checks region
      changed behavior; record the terminal outcome here `deps:` 3.5. Result: CLEAN
      in fresh round 1

## Lint without extraction

This is a record, not a phase.

The goal of extracting bodies to `.sh` files was to get them linted. That goal is
met without moving them, and better: `checks/check-bodies-shellcheck.nix` reads
each check's own `drvAttrs.buildCommand` and runs shellcheck over it. That string
is what bash actually executes, with every `${...}` already resolved to a store
path, so the gate lints the real artifact rather than a copy of it.

Why this is better than extraction, not merely cheaper:

- Extraction would rewrite 19 derivations and risk changing the tests while moving
  them. This changes none: the two derivations that did change, `wezterm-chord-collisions`
  and `openspec-default-schema`, changed because a finding was fixed.
- An extracted `.sh` cannot contain `${store paths}`, so extraction forces every
  path through an environment variable. That is a real behavior change to every
  check, made solely to satisfy the linter.
- Coverage is total and automatic. A check added later is linted with no further
  work, and cannot be forgotten.

The shell helpers stay local because their contracts differ.

Findings from turning the gate on, over roughly 1,500 previously-unlinted lines:

- 39 SC2154 and 5 SC1091: structurally false for a `runCommand` body, since stdenv
  sets `$out` and `$TMPDIR` and a sourced path is a store path. Excluded by rule,
  with the reason written at the exclusion.
- 4 SC2086 in `wezterm-chord-collisions`: deliberate word-splitting, one token per
  line. Given a targeted disable with that reason at each site.
- 1 SC2164 in `openspec-default-schema`: a genuinely unguarded `cd`. Fixed, not
  disabled. An unguarded `cd` that fails leaves every later assertion running in
  the wrong directory, which is the same defect class as the never-firing
  assertions this change was written to expose.

Mutation tested both directions: a real finding in any body fails the gate, and a
filter that matches nothing fails with "this gate covers nothing" rather than
passing green.

- The `checks/` shellcheck canary stays absent, because there are no `.sh` files
  under `checks/` and `require_nonempty` counts those. The new check is the
  coverage guard instead, and it has its own zero-coverage assertion.
- The single-use `cacheBundleFor` helper is gone. The `packages` output builds the
  bundle directly.
