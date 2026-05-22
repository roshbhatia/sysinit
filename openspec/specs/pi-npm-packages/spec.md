## ADDED Requirements

### Requirement: @sysid/pi-vim provides vim modal input
The pi configuration SHALL include `@sysid/pi-vim` v1.0.3 as a `fetchNpmPkg` derivation added to `piPackagesJson`.

#### Scenario: Vim modal input active in pi
- **WHEN** a pi session starts
- **THEN** the prompt editor supports normal mode (hjkl, dd, yy, operators) and insert mode

#### Scenario: Nix build succeeds
- **WHEN** home-manager is built
- **THEN** the `@sysid/pi-vim` derivation builds without error (no runtime deps, plain `fetchurl` for scoped package)

### Requirement: pi-tool-display provides compact tool rendering
The pi configuration SHALL include `pi-tool-display` v0.3.1 as a `fetchNpmPkg` derivation added to `piPackagesJson`.

#### Scenario: Tool output is compact
- **WHEN** pi executes tools during a session
- **THEN** tool call output uses compact rendering with diff visualization

### Requirement: pi-subdir-context injects subdirectory context
The pi configuration SHALL include `pi-subdir-context` v1.1.2 as a `fetchNpmPkg` derivation added to `piPackagesJson`.

#### Scenario: AGENTS.md injected from subdirectory
- **WHEN** pi reads a file in a subdirectory containing an `AGENTS.md`
- **THEN** that `AGENTS.md` is automatically injected as context

### Requirement: @psg2/pi-costs available as a CLI
The pi configuration SHALL include `@psg2/pi-costs` v1.0.1 in `home.packages` (not in piPackagesJson).

#### Scenario: pi-costs binary on PATH
- **WHEN** home-manager activation completes
- **THEN** `pi-costs` (or the package's bin) is available on `$PATH`
