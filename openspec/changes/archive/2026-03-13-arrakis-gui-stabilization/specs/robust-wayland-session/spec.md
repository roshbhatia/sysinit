## ADDED Requirements

### Requirement: Wayland Session Activation
The NixOS desktop environment SHALL correctly activate the user's `systemd` session upon login.

#### Scenario: Session target activation
- **WHEN** the user logs in via `greetd`
- **THEN** the `mango-session.target` SHALL reach an `active` state

### Requirement: Environment Propagation
Critical Wayland environment variables SHALL be exported to the systemd user instance and dbus.

#### Scenario: Variable export
- **WHEN** `mangowc` starts
- **THEN** `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` SHALL be visible to `systemctl --user show-environment`

### Requirement: Consistent Assets
The system SHALL use the "Retroism" official wallpaper by default.

#### Scenario: Wallpaper source
- **WHEN** the desktop is initialized
- **THEN** `swww` SHALL set the background using the image fetched from `github.com/diinki/linux-retroism`
