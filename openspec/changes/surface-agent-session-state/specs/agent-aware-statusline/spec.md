## ADDED Requirements

### Requirement: Name the worst blocked session in the statusline

The `tabline_y` agent-status component SHALL render the single most
action-needing session — its state icon, name, and age — instead of an aggregate
count, reading the shared session rollup. The worst session SHALL be selected by
the rollup precedence (`waiting > done > working > idle`, then longest age
first). When no session has agent state, the component SHALL render nothing (or
its prior empty form), not a zero count.

#### Scenario: Statusline names the waiting session

- **WHEN** session `auth-refactor` is `waiting` for 6 minutes and is the
  worst-ranked session
- **THEN** the statusline shows a waiting icon, `auth-refactor`, and `6m`

#### Scenario: Working-only state names the working session

- **WHEN** no session is `waiting` or `done` and `api` is `working`
- **THEN** the statusline names `api` with the working icon

#### Scenario: No agent state renders empty

- **WHEN** no session has any agent state
- **THEN** the agent-status component renders nothing
- **AND** it does not show a `0 working` style aggregate count

### Requirement: Statusline and switcher agree on the worst session

The statusline's named session SHALL be derived from the same rollup and the
same precedence the switcher uses, so the session named in the statusline is the
session the switcher sorts to the top.

#### Scenario: Both surfaces point at the same session

- **WHEN** the rollup ranks `auth-refactor` as the worst session
- **THEN** the statusline names `auth-refactor`
- **AND** the switcher lists `auth-refactor` first
