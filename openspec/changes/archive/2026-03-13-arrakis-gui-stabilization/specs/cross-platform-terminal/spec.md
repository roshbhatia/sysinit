## ADDED Requirements

### Requirement: Shared Terminal Config
The system SHALL provide a unified Wezterm configuration available to both Darwin and NixOS hosts.

#### Scenario: Wezterm installation
- **WHEN** building a NixOS desktop or a Darwin host
- **THEN** it SHALL include the `wezterm` package and its shared Lua configuration

### Requirement: Session Variable Consistency
Critical environment variables (e.g., `XDG_CONFIG_HOME`) SHALL be identical across platforms within the Wezterm environment.

#### Scenario: Config location
- **WHEN** Wezterm is launched on any host
- **THEN** it SHALL use the same configuration files managed by the `wezterm` home-manager module
