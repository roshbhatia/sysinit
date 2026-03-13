## ADDED Requirements

### Requirement: Physical Host Configuration
The system SHALL support physical NixOS host configurations that can opt-in to desktop-specific settings (Audio, GUI, Gaming) and host-specific hardware (NVIDIA drivers, Disk UUIDs).

#### Scenario: Arrakis Desktop
- **WHEN** building the `arrakis` host
- **THEN** it SHALL include `common` and `desktop` layers
- **AND** it SHALL include `arrakis` hardware configuration

### Requirement: Tiered Module Organization
The NixOS configuration SHALL be organized into `common`, `lima`, and `desktop` layers to avoid duplication and configuration leakage.

#### Scenario: Common settings
- **WHEN** any NixOS host is built
- **THEN** it SHALL include core settings like user/SSH/Nix regardless of platform

#### Scenario: Desktop layer exclusion
- **WHEN** building a non-desktop host (like a headless Lima VM)
- **THEN** it SHALL NOT include desktop-specific modules (PipeWire, Wayland)
