## ADDED Requirements

### Requirement: Append the blocked-session count to the statusline

The `tabline_y` agent-status component SHALL, alongside naming the worst blocked
session, append the total count of sessions currently holding actionable state
(`waiting`, `done`, or `working`) across all workspaces, so the user sees both
which session is worst and how many others are demanding attention. When exactly
one session has state, the count suffix MAY be omitted; when none has state, the
component SHALL render nothing (preserving the existing empty behavior).

#### Scenario: Multiple blocked sessions show a count

- **WHEN** four sessions hold actionable state and `auth-refactor` is worst
- **THEN** the statusline names `auth-refactor` with its icon and age and
  appends a total count of 4

#### Scenario: Single blocked session omits the count

- **WHEN** exactly one session holds actionable state
- **THEN** the statusline names that session with no redundant count suffix

#### Scenario: No blocked sessions render nothing

- **WHEN** no session holds actionable state
- **THEN** the agent-status component renders nothing
- **AND** it does not show a `0` count
