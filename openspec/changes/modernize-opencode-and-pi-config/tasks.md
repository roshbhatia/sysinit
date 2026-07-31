## 1. OpenCode config split and schema check

- **SHAPE** loop
- **STOP** both rendered files validate against the installed schemas and
  OpenCode writes no new migration backup
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
- **STOP** every key this repository has an opinion about is declared, no
  declared key is absent from the installed binary, and the stylix theme is
  active
- **MAX-ITERS** 4

- [ ] 2.1 Copy the live `~/.pi/agent/settings.json` into the change directory as
      the rollback artifact
- [ ] 2.2 Verify: the owner reads the captured file and names which drifted keys
      Nix takes over. `defaultProvider` and `defaultModel` stay undeclared
      regardless of the answer, per the proposal Non-goals; record the answer as
      input to a follow-up change
- [ ] 2.3 Remove `showLastPrompt` from `piManagedSettings`, and add it to a
      `piRetiredSettings` list that the activation script deletes from the live
      file before merging; undeclaring alone leaves the key on disk forever
- [ ] 2.4 Declare the agreed key set, excluding `defaultProvider` and
      `defaultModel` by name, and including `theme = "stylix"`,
      `enableInstallTelemetry = false`, a corrected `shellCommandPrefix` whose
      newline escape is right, and `skills` if
      `close-harness-instruction-gaps` has already landed it; the live capture
      hides that key, because the merge preserves it
- [ ] 2.5 Add a `nix flake check` derivation asserting every declared settings
      key appears in the installed pi binary (follows the hermetic checks at
      `flake.nix:229`; this cannot be a module-level `throw`, because
      evaluation cannot read a derivation's contents)
- [ ] 2.6 Add a build assertion that a generated theme file is selected by a
      declared setting
- [ ] 2.7 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 2.8 Verify: `nix flake check` and `nh darwin build` are green; review
      `git diff`
- [ ] 2.9 Apply: `nh darwin switch`
- [ ] 2.10 Confirm: the merged settings file carries the Nix values, the stylix
      theme is active in a pi session, `lastChangelogVersion` survived, and the
      alias prefix runs as a real multi-line prefix

## 3. Pi extension source and new extensions

- **SHAPE** loop
- **STOP** every vendored extension resolves inside the installed pi package
  and pi loads all of them without error
- **MAX-ITERS** 4

- [ ] 3.1 Source the vendored extension files from
      `${pkgs.pi-coding-agent}/pi/examples/extensions/` and delete
      `piExtensionsRev`, `piExtensionsSrc`, and their hash
- [ ] 3.2 Add a build assertion that every named extension exists in the package
- [ ] 3.3 Check `protected-paths` against `@gotgenes/pi-permission-system` for
      overlapping tool-call interception; record the result in `design.md`
- [ ] 3.4 Vendor `protected-paths`, `plan-mode`, and `modal-editor`, dropping
      any that 3.3 shows to conflict
- [ ] 3.5 Verify: the owner decides whether `externalEditor` points at
      `nvim-pi` or `nvim-pi` is removed from the profile
- [ ] 3.6 Apply the `nvim-pi` decision in `pi.nix` and in the keybindings file
- [ ] 3.7 Update `hack/update-pi.sh` so it no longer reports on a revision that
      no longer exists
- [ ] 3.8 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
- [ ] 3.9 Verify: `nix flake check`, `nh darwin build`, and
      `./hack/update-pi.sh` all behave as expected
- [ ] 3.10 Apply: `nh darwin switch`
- [ ] 3.11 Confirm: pi starts with no extension load error; `/plan` toggles;
      protected paths are blocked; the external editor opens or is gone

## 4. Stale directory cleanup

- **SHAPE** graph
- [ ] 4.1 List the contents of `~/.config/opencode/plugins/` and
      `~/.config/opencode/tools/` for the owner. Both are live plugin paths, so
      the cleanup removes files only, never the directories `deps: none`
- [ ] 4.2 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds `deps: 4.1`
- [ ] 4.3 Verify: the owner confirms each listed file is disposable `deps: 4.2`
- [ ] 4.4 Apply: copy the listed files into the change directory, then remove
      them `deps: 4.3`
- [ ] 4.5 Confirm: OpenCode starts and loses no configured plugin or tool
      `deps: 4.4`

## 5. Rollout

- [ ] 5.1 Verify: `openspec validate modernize-opencode-and-pi-config` passes
      and `specutil check` reports no finding
- [ ] 5.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed
- [ ] 5.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill
- [ ] 5.4 Confirm: the owner approves the staged diff before any commit
