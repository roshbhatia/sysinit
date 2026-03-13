## MODIFIED Requirements

### Requirement: 90s OS Palette
The system SHALL provide a "Classic Platinum" Base16 palette that replicates the aesthetic of 90s desktop operating systems.

#### Scenario: Wezterm full palette
- **WHEN** the `classic-platinum` theme is applied to Wezterm
- **THEN** the Wezterm configuration SHALL include an explicit `ansi` color array mapping to prevent indexing errors
