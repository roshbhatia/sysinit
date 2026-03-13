## ADDED Requirements

### Requirement: Built-in Retro Theme Support
The system SHALL support industry-standard retro Base16 themes provided by the upstream `base16-schemes` package.

#### Scenario: Windows 95 Light
- **WHEN** the `windows-95` theme is active with the `light` variant
- **THEN** Stylix SHALL use `windows-95-light.yaml` from the `base16-schemes` package
- **AND** Wezterm SHALL use its built-in `Windows 95 Light (base16)` color scheme
