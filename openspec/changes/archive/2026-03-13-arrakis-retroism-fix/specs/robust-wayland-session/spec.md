## MODIFIED Requirements

### Requirement: Wayland Session Activation
The NixOS desktop environment SHALL correctly activate the user's `systemd` session upon login.

#### Scenario: Session target activation
- **WHEN** the user logs in via `greetd`
- **THEN** the `mango-session.target` SHALL reach an `active` state
- **AND** the system SHALL explicitly start the target via the session wrapper

### Requirement: Environment Propagation
Critical Wayland environment variables SHALL be exported to the systemd user instance and dbus.

#### Scenario: Variable export
- **WHEN** `mangowc` starts
- **THEN** `WAYLAND_DISPLAY`, `XDG_CURRENT_DESKTOP`, and all other session variables SHALL be exported via `dbus-update-activation-environment --systemd --all`
