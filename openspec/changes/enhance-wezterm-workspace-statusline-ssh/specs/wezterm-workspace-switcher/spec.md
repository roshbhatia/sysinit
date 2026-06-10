## ADDED Requirements

### Requirement: Switcher offers the default workspace

The `SUPER+s` workspace switcher SHALL present a `default` entry pinned at the
top of its choices, ahead of the seshy sessions enumerated from `sy list`.
Selecting it SHALL switch to the `default` workspace via a switch action that
creates the workspace if it does not already exist.

#### Scenario: Default is the first choice

- **WHEN** the user opens the switcher with `SUPER+s`
- **THEN** the first choice is labeled `default` and the seshy sessions follow it

#### Scenario: Selecting default returns home

- **WHEN** the user is inside a seshy-session workspace and selects the `default`
  entry
- **THEN** the active workspace becomes `default`

#### Scenario: Default entry survives when no sessions exist (negative)

- **WHEN** `sy list` returns no sessions (its output is empty or only a header)
- **THEN** the switcher still lists the pinned `default` entry rather than
  presenting an empty chooser

### Requirement: New windows start in the default workspace

WezTerm SHALL launch every fresh window in the `default` workspace rather than
auto-restoring the most-recently-used session. `config.default_workspace` SHALL
be set to `default`, and the workspace-manager's startup auto-restore SHALL be
disabled (`session_restore_on_startup = false`) so it registers no `gui-startup`
restore handler that would override the default. Session state SHALL still be
saved and SHALL still be restored when a session is switched into via the
switcher.

#### Scenario: Relaunch lands on default

- **WHEN** the user quits WezTerm from inside a seshy-session workspace and
  relaunches the app
- **THEN** the new window opens in the `default` workspace rather than restoring
  the previously-active session

#### Scenario: New window opens in default

- **WHEN** the user opens a new top-level window (e.g. `CMD+N`)
- **THEN** that window starts in the `default` workspace

#### Scenario: Switching into a session still restores it (negative)

- **WHEN** the user selects a saved seshy session from the switcher after startup
- **THEN** that session's saved pane/tab state is still restored, since only the
  startup auto-restore is suppressed and `session_enabled` remains true

### Requirement: Switcher tolerates a missing session lister

The switcher choices override SHALL degrade gracefully when `sy` is unavailable
or errors, still offering the `default` entry.

#### Scenario: sy binary missing (negative)

- **WHEN** the `sy` binary cannot be resolved or exits non-zero
- **THEN** the switcher does not error and still presents the pinned `default`
  entry
