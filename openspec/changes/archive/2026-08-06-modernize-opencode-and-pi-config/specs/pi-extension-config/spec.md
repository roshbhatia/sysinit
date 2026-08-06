## MODIFIED Requirements

### Requirement: Per-extension config is generated, not hand-edited

Configuration files at `~/.pi/agent/extensions/<name>/config.json` MUST be
generated from `pi.nix` via `home.file` entries. Hand-edited config files at
these paths SHALL be overwritten on activation.

The home-manager activation script merges the `pi.nix` settings into
`~/.pi/agent/settings.json`. A key that `pi.nix` declares MUST win over a value
pi wrote at runtime. A key that `pi.nix` does not declare MUST be preserved,
because pi stores session bookkeeping there.

`pi.nix` MUST NOT declare a settings key that the installed pi build does not
recognize. A key absent from the installed build is dead configuration and
misreports the harness as configured.

Undeclaring a key MUST remove it from the live file. The activation merge is a
deep merge, so a key already written to disk survives every later activation
once Nix stops declaring it. The activation script MUST therefore carry an
explicit retired-key list and delete those keys before it merges. Without that
list, removing a key from `pi.nix` is a no-op against the running harness.

The declared key set MUST cover every setting this repository has an opinion
about, including the selected theme, so an owner-set runtime value cannot
silently replace the generated one.

#### Scenario: Activation overwrites a hand-edit

- **POLARITY** positive
- **WHEN** a user manually edits
  `~/.pi/agent/extensions/pi-tool-display/config.json` and then runs
  `nh darwin switch`
- **THEN** the activation step replaces the file with the Nix-generated version
- **AND** the activation log reports the file was replaced

#### Scenario: A Nix-declared key wins over a runtime value

- **POLARITY** positive
- **WHEN** pi writes a value at runtime for a key `pi.nix` declares, and the
  owner then runs `nh darwin switch`
- **THEN** the merged file carries the Nix value

#### Scenario: Runtime-written settings.json keys survive activation

- **POLARITY** positive
- **WHEN** pi writes a key that `pi.nix` does not declare and the owner runs
  `nh darwin switch`
- **THEN** that key is preserved

#### Scenario: A retired key leaves the live file

- **POLARITY** positive
- **WHEN** a key is added to the retired-key list and the owner runs
  `nh darwin switch`
- **THEN** the activation deletes that key from `~/.pi/agent/settings.json`
- **AND** a later activation does not reintroduce it

#### Scenario: Undeclaring a key without retiring it is caught

- **POLARITY** negative
- **WHEN** a key is removed from the declared set and is not added to the
  retired-key list
- **THEN** the build fails and names the key
- **AND** the message states that a deep merge cannot remove it

#### Scenario: A key the installed build does not recognize fails the build

- **POLARITY** negative
- **WHEN** `pi.nix` declares a settings key that does not appear in the
  installed pi build
- **THEN** the build fails and names the key
- **AND** the configuration does not reach the live machine

#### Scenario: A generated theme that is never selected fails the build

- **POLARITY** negative
- **WHEN** `pi.nix` generates a theme file and declares no setting selecting it
- **THEN** the build fails and names the unselected theme
