## Why

Two harness configs have drifted away from the tools they configure.

OpenCode 1.18 moved `theme`, `keybinds`, and the TUI settings out of
`opencode.json` into `tui.json`, and made `opencode.json` reject unknown keys.
OpenCode already migrated the live file and left
`~/.config/opencode/opencode.json.tui-migration.bak` behind. This repository
writes the old keys back on every activation, so the migration runs again every
time.

Pi's live settings file holds seven keys that Nix does not manage and pi wrote
at runtime, including a provider pinned to a free OpenRouter model and a
`shellCommandPrefix` whose newline escape is wrong. Of the three keys Nix does
manage, `showLastPrompt` does not exist in the installed pi build. The stylix
theme this repository generates is never selected. The extension TypeScript is
fetched from a pinned revision that reports version 0.74.0 while the installed
binary is 0.82.1, and that binary ships the matching files itself.

## What Changes

- Write OpenCode TUI settings to the TUI config file and stop writing them into
  the main config file.
- Declare the OpenCode settings this repository wants and does not yet set:
  the shell, the default agent, the subagent depth, the compaction thresholds,
  and the tool-output truncation limits.
- Validate the rendered OpenCode config against the JSON schema the installed
  build ships, so an upstream key move fails the build instead of the runtime.
- Take Nix ownership of pi's settings. Declare every key this repository has an
  opinion about, and stop preserving a runtime-written value for a key Nix
  declares.
- Remove `showLastPrompt`. It does not exist in the installed pi build.
- Select the generated stylix theme in pi's settings.
- Source pi's upstream extension TypeScript from the installed pi package
  instead of a separately pinned revision, which removes the version skew.
- Vendor `protected-paths`, `plan-mode`, and `modal-editor` from that same
  package, and either wire `externalEditor` to `nvim-pi` or remove `nvim-pi`.

### Non-goals

- Choosing pi's provider, model, or thinking level. Those are owner
  preferences. This change surfaces them for a decision and does not decide.
- Any notification or state-bus work. That belongs to
  `unify-agent-notification-layer`.
- Any context file or skills root. That belongs to
  `close-harness-instruction-gaps`.
- Copilot, cursor, goose, crush, amp, devin, gemini, claude, and codex config.
  Their gaps are real and are deliberately left for separate changes.
- OpenCode custom commands, references, the headless server, and skill URLs.

## Capabilities

### Modified Capabilities

- `harness-config-modernization`: add a requirement that a rendered harness
  config validates against the schema the installed build ships, and a
  requirement placing OpenCode TUI settings in the TUI config file.
- `pi-extension-config`: the requirement naming Nix-managed keys names
  `showLastPrompt`, which does not exist. It must name the real key set and
  state that a Nix-declared key wins over a runtime-written one.
- `pi-package-vendoring`: the requirement pins extension TypeScript to a
  separate revision. It must source those files from the installed pi package.

## Impact

Modified code:
- `modules/home/programs/llm/config/opencode.nix`
- `modules/home/programs/llm/config/pi.nix`
- `hack/update-pi.sh`

Dependencies:
- `pkgs.check-jsonschema` is added to the check closure. No flake input
  provides a JSON-schema validator today.
- The OpenCode schema check reads `share/opencode/config.json` and
  `share/opencode/tui.json` from the installed `pkgs.opencode` output. No new
  fetcher.
- Removing `piExtensionsSrc` removes one `fetchFromGitHub` and its hash.

Impactful and irreversible actions:
- `nh darwin switch` rewrites both live config files.
- Taking ownership of pi's drifted keys overwrites values the owner set through
  pi's own settings screen. Capture the current file before the switch.
- Removing `nvim-pi`, if that is the chosen outcome, removes a binary from the
  profile.
- Deleting the stale `~/.config/opencode/plugins/` and `tools/` directories
  removes untracked files. List them for the owner before deleting.

Gating signal:
- `nix flake check`, then `nh darwin build`, then a schema validation of the
  rendered config, then `nh darwin switch`. Each harness lands on its own.
- The kill switch for pi's settings ownership is three steps, in this order:
  revert the phase's commit, run `nh darwin switch`, then restore the captured
  settings file that the phase's first task wrote to the change directory.
  Restoring the file alone does not work. Every declared key is enforced, so
  activation reasserts it from Nix on every switch, not only when its Nix value
  changes. Until the commit is reverted, any later switch overwrites the restored
  file again.
