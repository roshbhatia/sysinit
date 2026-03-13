## ADDED Requirements

### Requirement: Bitmap Font Infrastructure
The system SHALL support the installation and enforcement of bitmap fonts for monospaced contexts on NixOS hosts.

#### Scenario: Terminus Deployment
- **WHEN** building the `arrakis` host
- **THEN** it SHALL include the `terminus_font` package
- **AND** it SHALL set Terminus as the default monospace font in Stylix and applications
