## ADDED Requirements

### Requirement: A rendered harness config validates against the installed build's schema

When a harness ships a machine-readable configuration schema in its own
package output, the rendered configuration for that harness MUST be validated
against that schema at build time.

Validation MUST use the schema from the installed derivation, not a copy in
this repository and not a schema fetched from the network. An upstream key move
or removal must therefore fail the build on the next version bump.

A harness that ships no schema is exempt, and the exemption is recorded beside
the harness config.

#### Scenario: The rendered config validates

- **POLARITY** positive
- **WHEN** the OpenCode configuration is rendered
- **THEN** it validates against `share/opencode/config.json` from the installed
  `opencode` derivation
- **AND** the TUI configuration validates against `share/opencode/tui.json`

#### Scenario: An upstream key move fails the build

- **POLARITY** negative
- **WHEN** a harness upgrade moves a key out of the schema this repository
  writes it into
- **THEN** the build fails and names the rejected key
- **AND** the failure occurs before the configuration reaches the live machine

#### Scenario: A key the schema forbids is rejected

- **POLARITY** negative
- **WHEN** the rendered configuration carries a key the schema does not declare
  and the schema forbids additional properties
- **THEN** the build fails and names the key

### Requirement: OpenCode TUI settings live in the TUI config file

OpenCode terminal-interface settings SHALL be written to the TUI configuration
file that the installed build declares, and SHALL NOT be written into the main
configuration file.

The main configuration file MUST NOT carry `theme`, `keybinds`, or a `tui`
block. OpenCode migrates those keys out on startup and leaves a backup file, so
writing them back makes the migration run on every activation.

Removing a key from the Nix-declared set MUST remove it from the live file. The
activation merge is a deep merge, so a key already on disk survives once Nix
stops declaring it. The activation script MUST delete an explicit retired-key
list before it merges. Without that deletion, moving the TUI keys out of the
main config leaves them on disk and OpenCode's migration runs again.

Validation MUST cover the merged file that OpenCode reads, not only the Nix
base. Validating the base alone cannot detect a stale key that the merge
preserved.

Validation therefore runs in two layers, because a `nix flake check`
derivation is hermetic and cannot see the live `$HOME`. The build-time layer
validates the Nix base plus a committed fixture pushed through the same
retired-key deletion and merge. The activation-time layer validates the real
merged file and fails `nh darwin switch`. Neither layer alone satisfies this
requirement.

#### Scenario: TUI keys land in the TUI file

- **POLARITY** positive
- **WHEN** the configuration is rendered
- **THEN** `theme`, `keybinds`, and the scroll settings appear in the TUI file
- **AND** the main configuration file contains none of them

#### Scenario: A migration backup is not regenerated

- **POLARITY** negative
- **WHEN** OpenCode starts after activation, having never started between the
  previous activation and this one
- **THEN** it writes no new TUI migration backup file
- **AND** the main configuration file is unchanged by the startup

#### Scenario: A retired key leaves the live file

- **POLARITY** positive
- **WHEN** the TUI keys are moved out of the Nix-declared set and the owner
  runs `nh darwin switch`
- **THEN** the activation deletes them from `~/.config/opencode/opencode.json`
- **AND** the merged file validates against the main schema

#### Scenario: A TUI key written to the main file fails the build

- **POLARITY** negative
- **WHEN** a contributor adds a TUI key to the main configuration attribute set
- **THEN** the schema validation fails and names the key
