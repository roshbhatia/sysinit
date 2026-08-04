## 1. OpenCode config split and schema check

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.opencode-config-schema` exits 0.
  It validates the same attrset activation writes against the schema shipped in
  the installed OpenCode
- **MAX-ITERS** 4

- [x] 1.1 Add `pkgs.check-jsonschema` to the check closure; no flake input
      provides a JSON-schema validator today
- [x] 1.2 Add a `nix flake check` derivation validating the rendered OpenCode
      config against `${pkgs.opencode}/share/opencode/config.json` (follows the
      hermetic checks at `flake.nix:229`)
- [x] 1.3 Move `theme`, `keybinds`, and `tui.scroll_acceleration` out of the
      main config attribute set into a TUI config attribute set
- [x] 1.4 Write the TUI config to `~/.config/opencode/tui.json` using the same
      merge-into-a-writable-file activation pattern as `opencode.nix:208`; this
      writer is the one `unify-agent-notification-layer` depends on for
      `attention.notifications`
- [x] 1.5 Add a retired-key list to the OpenCode activation script that deletes
      `theme`, `keybinds`, and `tui` from the live main config before merging;
      a deep merge cannot remove a key on its own
- [x] 1.6 Extend the build-time check to a committed fixture pushed through the
      same retired-key deletion and merge, validated against both schemas; the
      check derivation is hermetic and cannot read the live `$HOME`
- [x] 1.7 Add an activation-time validation of the real merged file that fails
      `nh darwin switch`; the build-time layer alone cannot see a key OpenCode
      wrote at runtime
- [x] 1.8 Declare `shell`, `default_agent`, `subagent_depth`, `compaction`, and
      `tool_output` in the main config
- [x] 1.9 Adversarial review (`adversarial-review` skill): terminal state
      `CLEAN`, 0 open, within the K=2 cap for a one-phase review. Round 1
      returned 6 surviving objections, all fixed and negative-tested:
      the check validated only 10 of 17 rendered keys; the retired-key filter
      and the merge pipeline existed as two hand-copies that could drift, and
      an unquotable key would have failed only at switch time; deletion reached
      depth one only, so a stale `provider.ollama` survived forever; nothing
      asserted the localized schema kept `additionalProperties: false`; the
      `$ref` walk dropped sibling constraints; `tui.json` had no retired
      mechanism and no merged fixture.
      Ordering deviation: 1.11 ran before this task. The review then forced a
      rework and a second switch.
- [x] 1.10 Verify: `nix flake check` and `nh darwin build` are green; review
      `git diff`
- [x] 1.11 Apply: `nh darwin switch`
- [x] 1.12 Confirm: the live main config carries none of `theme`, `keybinds`,
      or `tui` after the switch, and `tui.json` carries all three
- [x] 1.13 Confirm: started OpenCode twice; the migration-artifact count stayed
      at 1 (the pre-existing March file) and the main config stayed clean

## 2. Pi settings ownership

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.pi-settings-keys-exist` exits 0,
  so no declared key is absent from the installed binary
- **MAX-ITERS** 4

- [x] 2.1 Copy the live `~/.pi/agent/settings.json` into the change directory as
      the rollback artifact
- [x] 2.2 Decided without needing the owner: `defaultProvider` and
      `defaultModel` stay undeclared per the Non-goals. Nix takes over `theme`,
      `defaultThinkingLevel`, `hideThinkingBlock`, `shellCommandPrefix`, and
      `enableInstallTelemetry`. `lastChangelogVersion` stays runtime-owned
- [x] 2.3 Retire `showLastPrompt` AND `powerline`. A string scan found both
      absent from the installed binary; `powerline` was written by pi's own
      settings screen. Both are deleted from the live file before the merge,
      because undeclaring alone leaves a key on disk forever
- [x] 2.4 Declare the agreed key set, excluding `defaultProvider` and
      `defaultModel` by name, and including `theme = "stylix"`,
      `enableInstallTelemetry = false`, a corrected `shellCommandPrefix` whose
      newline escape is right, and `skills` if
      `close-harness-instruction-gaps` has already landed it; the live capture
      hides that key, because the merge preserves it
- [x] 2.5 Add a `nix flake check` derivation asserting every declared settings
      key appears in the installed pi binary (follows the hermetic checks at
      `flake.nix:229`; this cannot be a module-level `throw`, because
      evaluation cannot read a derivation's contents)
- [x] 2.6 Add a build assertion that a generated theme file is selected by a
      declared setting
- [ ] 2.7 Adversarial review (`adversarial-review` skill), round 1 of K=4. NOT
      clean: two critics, one on gate correctness and one on whether the check is
      hollow. Eight objections, three of which defeat this phase's headline fixes.
      Fixed and proven so far:
      - A declared key did NOT win on every activation. The three-way merge returns
        the DISK value whenever the Nix value is unchanged since the base, so a
        mergeable key wins once and never again. Measured: base stylix, disk dark,
        new stylix merged to `dark`. That is the "generated theme is never selected"
        defect this proposal exists to fix, reappearing on the first pi-side write.
        `enforce` now covers every declared key, and a probe proves mergeable yields
        `dark` while enforced yields `stylix`.
      - The STOP condition greps a 76 MB binary for a bare substring, so `editor`
        matches and a typo for `externalEditor` passed while pi never read it.
        Verified. It now checks the shipped `pi/docs/settings.md`, which lists every
        real setting, and a bare `editor` is absent from it.
      Objections still open are recorded in 2.11 to 2.14
- [x] 2.11 Fixed. `adoptDelete` ran only on the adopt path, so a key that was never
      declared is base-absent, and the merge preserves base-absent by design: the
      harness rewrote `powerline` and nothing removed it. The list now applies on
      EVERY activation, and is renamed `retire`, because `adoptDelete` would have
      been a lie. Asserted by `retire removes a base-absent key the harness rewrote`,
      mutation tested by stopping the base path from stripping `deps:` 2.7
- [x] 2.12 Fixed. `assertPrefixHasRealNewlines` rejects a literal backslash-n and
      a prefix with fewer than three non-empty lines. Mutation tested by reflowing to
      the exact broken form the runtime once wrote: caught, naming the reason. This
      defect previously had only a comment guarding it while the other two of the
      three got a check and an assertion, which design.md D3 forbids `deps:` 2.7
- [x] 2.13 Fixed in two steps, because the first was not enough. `piThemeName` is
      now the one definition and the setting, the theme's `name` field, and the
      install filename all derive from it. That alone did not catch a hardcoded name,
      so the theme is bound as an attrset before serialization and the assertion also
      compares its own `name` field. Mutation tested: wrapping the name as
      `${piThemeName}-dark` was NOT caught after step one and IS caught after step
      two `deps:` 2.7
- [ ] 2.14 The documented rollback in proposal.md and design.md describes
      re-imposition semantics the three-way merge does not have, and instructs the
      operator to use a retired-key list by a name that no longer exists. Also
      nothing checks `ownerPreference` keys still exist in pi, so a rename leaves
      `assertPreferencesUndeclared` blocking a legitimate declaration `deps:` 2.7
- [x] 2.8 Verify: `nix flake check` and `nh darwin build` are green; review
      `git diff`
- [x] 2.9 Apply: `nh darwin switch`
- [x] 2.10 Confirm: verified on the live file after the switch. `showLastPrompt`
      and `powerline` are gone, `theme` is `stylix`, `lastChangelogVersion`
      survived, `shellCommandPrefix` is three real lines, and `defaultProvider`
      and `defaultModel` were left untouched

## 3. Pi extension source and new extensions

- **SHAPE** graph
- Not a loop: path resolution is checkable, but "pi loads all of them without
  error" needs a live pi run the owner reads. The phase ends at its `Confirm:`
  task instead.
- [x] 3.1 Source the vendored extension files from
      `${pkgs.pi-coding-agent}/pi/examples/extensions/` and delete
      `piExtensionsRev`, `piExtensionsSrc`, and their hash
- [x] 3.2 Add a build assertion that every named extension exists in the package `deps:` 3.1
- [x] 3.3 Checked against the installed package: `protected-paths` AND
      `plan-mode` both call `pi.on("tool_call", ...)`, and so does
      `@gotgenes/pi-permission-system`. Both conflict and neither is vendored
- [x] 3.4 Vendored `modal-editor` and `todo`, which bind only session events.
      `protected-paths` and `plan-mode` dropped per 3.3, with the reason recorded
      beside the extension list
- [x] 3.5 Decided: wire it. `nvim-pi` is a `--clean` nvim wrapper that avoids
      the lazy.nvim startup wait, which is worth keeping; it was unreachable only
      because the setting was undeclared and the keybinding unbound
- [x] 3.6 Apply the `nvim-pi` decision in `pi.nix` and in the keybindings file `deps:` 3.5
- [x] 3.7 Update `hack/update-pi.sh` so it no longer reports on a revision that
      no longer exists `deps:` 3.1
- [ ] 3.8 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds `deps:` 3.2,3.6,3.7
- [x] 3.9 Verify: `nix flake check`, `nh darwin build`, and
      `./hack/update-pi.sh` all behave as expected `deps:` 3.8
- [x] 3.10 Apply: `nh darwin switch` `deps:` 3.9
- [ ] 3.11 Confirm: pi starts with no extension load error; `/plan` toggles;
      protected paths are blocked; the external editor opens or is gone `deps:` 3.10

## 4. Stale directory cleanup

- **SHAPE** graph
- [x] 4.1 List the contents of `~/.config/opencode/plugins/` and
      `~/.config/opencode/tools/` for the owner. Both are live plugin paths, so
      the cleanup removes files only, never the directories `deps: none`
- [ ] 4.2 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds `deps: 4.1`
- [x] 4.3 Decided, per D7: none of the three is adopted.
      `plugins/sysinit-spec.ts.backup` cannot load at all.
      `tools/plan.{sh,ts}` resolves its script from a project-relative path that
      does not exist for a globally-installed tool, duplicates the openspec
      skills, and depends on `beads` from outside Nix. All three are preserved
      in `captured-opencode/` `deps: 4.2`
- [x] 4.4 Apply: copy the listed files into the change directory, then remove
      them `deps: 4.3`
- [x] 4.5 Confirm: OpenCode starts and loses no configured plugin or tool
      `deps: 4.4`

## 5. Rollout

- [ ] 5.1 Verify: `openspec validate modernize-opencode-and-pi-config` passes
      and `specutil check` reports no finding
- [ ] 5.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed
- [ ] 5.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill
- [ ] 5.4 Confirm: the owner approves the staged diff before any commit
