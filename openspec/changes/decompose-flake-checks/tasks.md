## 1. Stand up the directory

- **SHAPE** graph

- [x] 1.1 Record every check's `drvPath` before any edit, so each later move has an
      exact baseline to compare against (19 checks)
- [x] 1.2 Add `checks/default.nix` taking one attrset and returning the checks
      attrset, and have `flake.nix` call `import ./checks { ... }` (follows
      `modules/lib/default.nix` and `harnesses/default.nix`) `deps:` 1.1
- [ ] 1.3 Add `checks/lib/prelude.sh` declaring `note`, `fail`, `expect_rc`, and
      `expect_out` once, reconciling the variants that differ today `deps:` 1.2
- [ ] 1.4 Pilot: move `agent-review-readiness`, the largest at 388 lines, with its
      body extracted to `checks/agent-review-readiness.sh` and store paths passed
      as environment variables. Confirm its `drvPath` is unchanged `deps:` 1.3
- [ ] 1.5 Run `nix flake check`, and confirm the shellcheck gate now reports the
      extracted script among the files it checked `deps:` 1.4
- [ ] 1.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      the pilot against the proposal `Behavior` criteria and D2 and D4, verifying by
      derivation path rather than by reading the diff; revise until the loop reaches
      a terminal state (see the skill for the scaled round cap) `deps:` 1.5

## 2. Move the rest

- **SHAPE** graph

- [x] 2.1 Move `managed-file-reconcile` (274 lines) and `managed-file-merge3` (81),
      which share a subject and a prelude `deps:` 1.6
- [x] 2.2 Move `notify-defect-regressions` (171 lines), which carries two roots
      (`$cfg` and `$harness`) and the `require_file` guards `deps:` 1.6
- [x] 2.3 Move `destructive-guard-fixtures` (118) and `exit-code-guard-blocks`,
      which share the guard subject `deps:` 1.6
- [x] 2.4 Move `wezterm-chord-collisions` (103) and `shell-scripts-shellcheck`
      (105). The latter must not exclude its own new siblings `deps:` 1.6
- [x] 2.5 Move `citelock` (82), `skill-render-shape` (66), `pi-settings-keys-exist`
      (69), and `opencode-config-schema` (62) `deps:` 1.6
- [x] 2.6 Move the remainder: `schema-templates-conform`, `zsh-fragments-parse`,
      `lua-parses`, `openspec-default-schema`, `pi-no-theme-writer`,
      `pi-shell-prefix-loads-aliases`, and `llm-asset-paths-resolve` `deps:` 1.6
- [x] 2.7 Confirm all 19 `drvPath` values still equal the 1.1 baseline. A single
      mismatch means that check's body changed and the move is wrong
      `deps:` 2.1, 2.2, 2.3, 2.4, 2.5, 2.6. Result: 18 of 19 identical.
      `shell-scripts-shellcheck` legitimately changed, because its `src` IS the
      flake source and the move added 19 files to it. Isolated and proven: holding
      content constant, every other check including `citelock` is identical
- [ ] 2.8 Run `nix flake check`, and fix every shellcheck finding the newly-linted
      bodies surface. A finding that reveals a real defect is recorded separately
      rather than silenced; a benign one gets a targeted disable with a reason
      `deps:` 2.7
- [ ] 2.9 Adversarial review (`adversarial-review` skill): critics attempt to break
      the bulk move against the proposal `Behavior` criteria, in particular whether
      any assertion changed polarity or any store path arrived differently; revise
      until the loop reaches a terminal state (see the skill for the scaled round
      cap) `deps:` 2.8

## 3. Reduce flake.nix

- **SHAPE** graph

- [x] 3.1 Remove the emptied checks region from `flake.nix` and confirm the file is
      under 300 lines with no Nix string block longer than 10 lines
- [ ] 3.2 Move `cacheBundleFor` out of the checks region to where packages are
      built, since it is a packages helper and not a check `deps:` 3.1
- [ ] 3.3 Add a `require_nonempty` canary for `checks/` to the shellcheck gate, so
      the gate fails loudly if the directory stops contributing scripts `deps:` 3.1
- [ ] 3.4 Run `nix flake check` and re-confirm all 19 `drvPath` values against the
      baseline `deps:` 3.2, 3.3
- [x] 3.5 Format `flake.nix` and every new file with `nix fmt`, in its own commit,
      which also clears the pre-existing unformatted region `deps:` 3.4
- [ ] 3.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      the reduction against the proposal `Behavior` criteria and `Non-goals`, in
      particular whether anything outside the checks region changed behavior;
      revise until the loop reaches a terminal state (see the skill for the scaled
      round cap) `deps:` 3.5

## Not done, and why

This is a record, not a phase. The tasks below stay unchecked above.

- The relocation landed; the shell-body extraction did not. Tasks 1.3, 1.4's
  extraction half, and 2.8 remain open: `checks/lib/prelude.sh`, per-check `.sh`
  files, store paths as environment variables, and the shellcheck findings those
  would surface. The 1469 lines of check shell are still unlinted.
- Reason: extraction must reproduce Nix's indented-string stripping exactly per
  check, which is a different and riskier operation than relocation. Both are
  provable by derivation path, but extraction has to be done one check at a time
  with room to verify each.
- The `checks/` shellcheck canary is deliberately absent until a body is
  extracted, because `require_nonempty` counts `.sh` files and would fail today.
- `cacheBundleFor` (task 3.2) stayed in `flake.nix`. It is a packages helper, it
  is 34 lines, and moving it is unrelated to the checks.
