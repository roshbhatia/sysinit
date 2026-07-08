## ADDED Requirements

### Requirement: Show rolled-up agent state in the session switcher

The seshy session switcher (`wm.get_choices`) SHALL enrich each session choice's
label with that session's rolled-up agent state — a state icon, the reason, and
the age — read from the shared session rollup. Sessions with no agent state
SHALL render their bare name as before. The switcher MAY perform its existing
`sy list` shell-out (it runs only when the switcher opens), but it SHALL source
agent state from the same rollup the statusline uses rather than recomputing it.

#### Scenario: Blocked session shows state, reason, and age

- **WHEN** the switcher opens and session `auth-refactor` is rolled up as
  `waiting` on `needs approval` for 6 minutes
- **THEN** that session's label includes a waiting icon, the reason, and `6m`

#### Scenario: Session without agents shows a bare name

- **WHEN** the switcher opens and session `notes` has no agent state
- **THEN** its label is the plain session name with no state decoration

#### Scenario: Pinned default entry still appears

- **WHEN** the switcher opens
- **THEN** the pinned `default` entry is still present and is not required to
  carry agent state

### Requirement: Sort the switcher by urgency

The switcher SHALL order session choices so that the most action-needing
sessions appear first, using the rollup precedence (`waiting > done > working >
idle`, then longest age first), with stateless sessions ordered after stated
ones.

#### Scenario: Longest-blocked session sorts to the top

- **WHEN** two sessions are `waiting`, one for 6 minutes and one for 1 minute
- **THEN** the 6-minute session is listed above the 1-minute session

#### Scenario: Stateless sessions sort below stated ones

- **WHEN** one session is `working` and another has no agent state
- **THEN** the `working` session is listed above the stateless session
