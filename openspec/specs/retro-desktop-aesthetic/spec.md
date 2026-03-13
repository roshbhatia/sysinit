## ADDED Requirements

### Requirement: Blocky Window Decorations
The NixOS desktop SHALL use non-rounded (0px radius) corners for all windows and UI components.

#### Scenario: Mango window rendering
- **WHEN** a window is opened in `mangowc`
- **THEN** it SHALL have a `border_radius` of 0
- **AND** it SHALL have a solid 1px border

### Requirement: Artifact-Free Rendering
The NixOS desktop SHALL disable all transparency and blur effects to ensure stable rendering on NVIDIA hardware.

#### Scenario: Blur and Shadows
- **WHEN** the desktop environment is initialized
- **THEN** Gaussian blur and soft shadows SHALL be disabled in the compositor settings

### Requirement: Flush Tiling
The NixOS desktop SHALL use a gapless tiling layout by default.

#### Scenario: Window gaps
- **WHEN** multiple windows are tiled
- **THEN** the inner and outer gaps SHALL be 0px, causing windows to sit flush against each other and the screen edges
