## Archive Status

The owner abandoned this change during OpenSpec housekeeping on 2026-08-05.

Thirty-four of 76 tasks were complete. The unchecked tasks remain unchanged.
This archive does not promote its delta specifications to `openspec/specs/`.
A later focused change can reconcile delivered behavior with canonical specs.

## Why

The agent, shell, and WezTerm surfaces carry roughly 8,500 lines of authored
configuration. No check covers any of them. `nix flake check` defines three
checks and all three guard the OpenSpec workflow. No CI job runs `nix flake
check` or builds a host configuration, so even those three run only when the
owner runs them.

The result is a set of failures that ship green and surface later at runtime.
One is already live: `lib/allowlist.nix:254` declares the destructive-command
patterns as the single source, and `claude-bash-guard.sh` inlines its own
copies. Four of the six patterns have drifted between the two.

## What Changes

- Add parse and lint checks for every authored fragment. Nix-embedded zsh gets
  `zsh -n`. WezTerm Lua gets a syntax check. Every `.sh` under the LLM module
  gets shellcheck.
- Add a CI job that runs `nix flake check` and builds a host configuration on
  every push to `main` and on every pull request.
- Contain WezTerm configuration failures. `core.setup` stays mandatory. The
  cosmetic modules load under `pcall` so one Lua error no longer costs the
  owner their shell environment.
- Declare WezTerm chords in Nix. Render the same list to Lua and to the
  cross-layer collision assertion in `modules/darwin/keybindings.nix`.
- Version the agent state bus. Add a schema, a round-trip check, and stale
  entry collection that does not depend on a per-harness exit hook.
- Add `sysinit doctor`, a command that reports drift between the built
  configuration and the running machine.
- Make the guard scripts consume `llmLib.allowlist.destructiveDenyRegexes`
  instead of inlining copies. Add a fixture check over the deny set.

Reused patterns:

- `flake.nix:229` already defines hermetic `pkgs.runCommand` checks with a
  tmp `HOME`. Every new check follows that shape.
- `modules/darwin/keybindings.nix:151` already models chords as strings and
  asserts across layers. The WezTerm layer joins that model.
- `modules/home/programs/llm/lib/acp.nix` already holds one registry rendered
  per consumer. The chord registry follows it.
- `modules/home/programs/wezterm/default.nix:130` already renders Nix values
  into `wezterm/config.json` for Lua to read. The chord list joins that file.
- `modules/home/programs/llm/config/notify.nix:77` already packages an
  `agent-*` script into `home.packages`. `sysinit doctor` follows it.

### Non-goals

- Changing the permission model. `dangerouslySkipPermissions = true` and
  `sandbox.enabled = false` stay. Explicit guards are the chosen design, not a
  gap to close. This change tests the guards and removes their drift. It does
  not narrow what the agent may do.
- Widening the deny set. The patterns in `lib/allowlist.nix` stay as they are.
- Replacing regex command matching with a shell parser. The guard stays
  best-effort and fail-open.
- Gating anything other than `main`. Branch protection and the required status
  check are in scope, but only to make the Dependabot auto-merge wait. An
  adversarial review showed the gate is worthless without them: the existing
  automation merges with `--squash` about five seconds after a pull request
  opens, so the dependency bumps most likely to break the build were the least
  gated. The owner relaxed this non-goal after that finding.
- Rewriting `ui.lua`. Containment wraps it; it does not restructure it.
- Managing `~/.zshenv`, `~/.zshsecrets`, or `$XDG_CONFIG_HOME/zsh/extras/`.
  They stay unmanaged escape hatches. `sysinit doctor` only reports them.
- Auditing the third-party WezTerm plugins or their patches.

## Capabilities

### New Capabilities

- `config-verification-gate`: parse and lint checks over Nix-embedded zsh,
  WezTerm Lua, and LLM shell scripts, plus the CI job that runs `nix flake
  check` and a host build on every push and pull request.
- `wezterm-config-containment`: a WezTerm entrypoint where a failure in a
  cosmetic module degrades that module only, reports itself, and never costs
  the owner `default_prog`, `PATH`, or the keybinding set.
- `wezterm-chord-registry`: WezTerm chords declared once in Nix, rendered to
  Lua and to the cross-layer collision assertion, with intra-WezTerm duplicates
  rejected at evaluation.
- `agent-state-bus-contract`: a versioned, schema-validated per-pane state
  file, a round-trip check over the emitter, and stale entry collection that
  does not depend on a per-harness exit hook.
- `sysinit-doctor`: a command that reports drift between the built
  configuration and the running machine.

### Modified Capabilities

- `cross-harness-destructive-command-guard`: the guard scripts consume the
  shared pattern list instead of inlining copies, and a check asserts each
  pattern denies its target form while the allowed forms still pass.

## Impact

Modified code:

- `flake.nix`
- `.github/workflows/` (new check job)
- `AGENTS.md`
- `modules/home/programs/wezterm/default.nix`
- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`
- `modules/darwin/keybindings.nix`
- `modules/darwin/options.nix`
- `modules/home/programs/llm/lib/allowlist.nix`
- `modules/home/programs/llm/config/claude-bash-guard.sh`
- `modules/home/programs/llm/config/claude.nix`
- `modules/home/programs/llm/config/codex.nix`
- `modules/home/programs/llm/config/agent-state.sh`
- `modules/home/programs/llm/config/notify.nix`
- `modules/lib/shell.nix`

Dependencies: none new at runtime. Checks pull `pkgs.shellcheck`,
`pkgs.zsh`, `pkgs.lua` or `pkgs.luajit`, and `pkgs.jq`, all already in nixpkgs
and several already in `modules/home/packages.nix`.

Impactful and irreversible actions:

- `nh darwin switch` on each slice that changes generated dotfiles. Slices 2
  through 6 all reach the live system.
- `git push` to `main`. This repository permits it once directed.
- Adding a CI workflow file. A workflow change needs the `workflow` PAT scope
  to merge through the existing Dependabot automation.
- Rewriting `claude-bash-guard.sh` to read generated patterns. A regression
  here weakens the only mechanical floor under the agent's Bash tool, so the
  fixture check lands before the rewrite, not after.

Gating signal: the default repository sequence, `nix flake check`, then `nh
darwin build`, then owner spot-check, then `nh darwin switch`. The WezTerm
containment slice adds a runtime gate: the owner reproduces a Lua error and
confirms the terminal still starts with a working shell.

The change is shaped to land in six independent slices. Slice 1 stands alone
and makes every later slice enforceable. No slice depends on a later one.
