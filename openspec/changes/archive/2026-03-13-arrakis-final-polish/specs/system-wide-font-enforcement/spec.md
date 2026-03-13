## ADDED Requirements

### Requirement: Accurate Font Mapping
The system SHALL map installed font packages to their exact family names as recognized by fontconfig.

#### Scenario: Terminess Nerd Font
- **WHEN** building the `arrakis` host
- **THEN** the monospace font family SHALL be set to `Terminess Nerd Font`
