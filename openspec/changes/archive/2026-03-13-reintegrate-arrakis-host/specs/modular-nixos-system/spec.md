## ADDED Requirements

### Requirement: Modular Configuration Structure
The system SHALL follow a flat, modular structure in `modules/nixos/` that matches the `modules/darwin/` pattern.

#### Scenario: Module import
- **WHEN** the `default.nix` in `modules/nixos/` is imported
- **THEN** it SHALL conditionally import system modules based on the host configuration

### Requirement: Dynamic Home Directory
The system SHALL dynamically determine the user's home directory based on whether the host is a virtual (Lima) or physical system.

#### Scenario: Virtual host home
- **WHEN** the host is a Lima instance
- **THEN** the home directory SHALL be set to `/home/user.linux`

#### Scenario: Physical host home
- **WHEN** the host is a physical system
- **THEN** the home directory SHALL be set to `/home/user`
