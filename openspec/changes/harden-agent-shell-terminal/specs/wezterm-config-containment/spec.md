## ADDED Requirements

### Requirement: The environment layer loads unconditionally

`sysinit.pkg.core` sets `default_prog`, `PATH`, `SHELL`, `TERM`, and
`TERMINFO_DIRS` from `env.json`. It MUST run before any other module and MUST
NOT be wrapped in error handling. A failure there is not recoverable and MUST
surface as a configuration error rather than as a terminal with the wrong
shell.

#### Scenario: Core applies before the cosmetic modules

- **POLARITY** positive
- **WHEN** WezTerm evaluates the configuration
- **THEN** `core.setup` runs first
- **AND** `default_prog` points at the Nix zsh

#### Scenario: A core failure is not swallowed

- **POLARITY** negative
- **WHEN** `env.json` is absent or unreadable
- **THEN** the failure propagates rather than being caught and ignored
- **AND** the owner sees a configuration error naming `core`

### Requirement: A cosmetic module failure degrades only that module

`sysinit.pkg.events`, `sysinit.pkg.keybindings`, and `sysinit.pkg.ui` MUST each
load under `pcall`. A failure in one MUST NOT prevent the others from loading
and MUST NOT prevent the configuration from returning.

Today all four modules load unguarded, so a runtime error in `ui.lua`, which is
over 2,000 lines, aborts the whole configuration.

#### Scenario: A UI failure keeps keybindings and the shell

- **POLARITY** positive
- **WHEN** `ui.setup` raises a runtime error
- **THEN** the configuration still returns
- **AND** `keybindings.setup` has still applied its key table
- **AND** the pane still starts the Nix zsh with the configured `PATH`

#### Scenario: A keybindings failure does not disable default bindings

- **POLARITY** negative
- **WHEN** `keybindings.setup` raises before it sets
  `disable_default_key_bindings`
- **THEN** the terminal is left with usable bindings rather than none
- **AND** the failure is reported

### Requirement: A contained failure is visible

A caught module failure MUST be reported through at least one channel the owner
sees without opening a log file. Silent degradation is a defect: a terminal
that works but is subtly wrong is harder to diagnose than one that fails.

The report MUST name the module and carry the Lua error text.

#### Scenario: A caught failure reaches the owner

- **POLARITY** positive
- **WHEN** `ui.setup` fails and the failure is caught
- **THEN** the module name and error text are written to the WezTerm error log
- **AND** the owner receives a visible signal that does not require reading
  that log

#### Scenario: A failure is never swallowed silently

- **POLARITY** negative
- **WHEN** a module fails and the reporting channel itself fails
- **THEN** the configuration still returns
- **AND** the failure is still written to the WezTerm error log

### Requirement: The fallback behavior is recorded, not assumed

The design assumes that an aborted WezTerm configuration leaves the terminal on
its built-in defaults. That assumption MUST be verified by reproducing a Lua
error and recording the observed behavior before the containment is accepted as
correct.

#### Scenario: The observed behavior is recorded

- **POLARITY** positive
- **WHEN** the owner injects a deliberate error into `ui.lua` and starts WezTerm
- **THEN** the observed behavior is recorded in the change design
- **AND** the containment is evaluated against the observed behavior

#### Scenario: The observed behavior contradicts the assumption

- **POLARITY** negative
- **WHEN** the reproduction shows WezTerm behaves differently from the
  assumption
- **THEN** the design records the actual behavior
- **AND** the containment is reshaped before it ships
