## ADDED Requirements

### Requirement: Laurel marketplace and plugin install are host-gated

The `pinginc/ai-tooling` Claude Code marketplace MUST be registered, and
the `Laurel@Laurel` plugin MUST be installed, only on hosts whose
`home.username` resolves to `roshan` (the work-host identifier in
`hosts/default.nix`). Personal hosts (those whose username is `rshnbhatia`)
SHALL receive neither the marketplace registration nor the plugin install.
The activation step that performs these actions MUST be wrapped in a
`lib.mkIf` guard keyed on the resolved username, so that the imperative
work happens at build/eval time, not at runtime.

#### Scenario: Work host receives marketplace and plugin

- **WHEN** `nh os switch` (or `nh darwin switch`) is run on a host whose
  `home.username` is `roshan`
- **THEN** `~/.claude/plugins/known_marketplaces.json` contains a `Laurel`
  entry whose `source.repo` is `pinginc/ai-tooling`
- **AND** `~/.claude/plugins/installed_plugins.json` lists
  `Laurel@Laurel` under `plugins`

#### Scenario: Personal host receives neither

- **WHEN** `nh os switch` is run on a host whose `home.username` is
  `rshnbhatia`
- **THEN** the activation step is not executed
- **AND** if `~/.claude/plugins/known_marketplaces.json` exists, it does
  not gain a `Laurel` entry as a result of the activation
- **AND** if `~/.claude/plugins/installed_plugins.json` exists, it does
  not gain a `Laurel@Laurel` entry as a result of the activation

### Requirement: Activation is idempotent

The activation step MUST detect existing state before running each
imperative command. It SHALL skip `claude plugin marketplace add
pinginc/ai-tooling` when a marketplace named `Laurel` is already present
in `~/.claude/plugins/known_marketplaces.json`. It SHALL skip
`claude plugin install Laurel@Laurel` when a plugin matching
`Laurel@Laurel` is already present in
`~/.claude/plugins/installed_plugins.json`. The step MUST succeed (exit
zero) when both checks pass with nothing to do.

#### Scenario: Re-activation with both already present is a no-op

- **WHEN** a user re-runs `nh os switch` on a work host that already has
  the marketplace registered and the plugin installed
- **THEN** the activation step exits zero without invoking either
  `claude plugin marketplace add` or `claude plugin install`

#### Scenario: Partial state — marketplace registered, plugin missing

- **WHEN** the marketplace is registered but the plugin was uninstalled
  by the user and `nh os switch` is re-run
- **THEN** the activation step skips the marketplace `add` and runs only
  `claude plugin install Laurel@Laurel`
- **AND** the activation exits zero after the install completes

#### Scenario: Claude binary missing at activation time

- **WHEN** the activation step runs on a host where the `claude` binary
  is not yet on PATH (e.g., a regression in `programs.claude-code.enable`)
- **THEN** the step exits non-zero with a message naming the missing
  `claude` binary, rather than silently skipping or proceeding

### Requirement: Auto-update toggle remains a documented user action

The Laurel marketplace auto-update toggle MUST remain a one-time manual
user action and SHALL NOT be managed declaratively by this change. It is
set only via the Claude Code TUI (`/plugin → Marketplaces → Laurel → Enable auto-update`) and is NOT
managed declaratively by this change. The tasks list MUST include a
one-time human-verification step instructing the user to enable
auto-update after the initial install. Subsequent updates to the
plugin's components are then handled by Claude Code itself on startup
and SHALL NOT be re-driven by activation.

#### Scenario: Initial install includes a manual auto-update step

- **WHEN** a user reads `tasks.md` for this change
- **THEN** there is a "Confirm" step instructing the user to enable
  auto-update in the Claude TUI after the first successful install
- **AND** the activation script does not attempt to mutate any
  auto-update setting itself

#### Scenario: Auto-update setting drift is tolerated

- **WHEN** auto-update is disabled by the user after activation
- **THEN** the activation step on next `nh os switch` SHALL NOT
  re-enable it, because that state is owned by the user via the TUI
