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

### Requirement: Switcher tolerates a missing session lister

The switcher choices override SHALL degrade gracefully when `sy` is unavailable
or errors, still offering the `default` entry.

#### Scenario: sy binary missing (negative)

- **WHEN** the `sy` binary cannot be resolved or exits non-zero
- **THEN** the switcher does not error and still presents the pinned `default`
  entry
