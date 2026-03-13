## MODIFIED Requirements

### Requirement: Blocky Window Decorations
The NixOS desktop SHALL use non-rounded (0px radius) corners for all windows and UI components.

#### Scenario: Waybar menu bar
- **WHEN** the `waybar` is rendered
- **THEN** it SHALL have a `border-radius` of 0
- **AND** it SHALL have `exclusive` mode set to `true` to ensure visibility
