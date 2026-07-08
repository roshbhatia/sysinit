## MODIFIED Requirements

### Requirement: Show rolled-up agent state in the session switcher

The `SUPER+s` switcher SHALL be realized as the session tree
(`session-tree-switcher`): its top-level nodes are the seshy sessions/workspaces, each
enriched with that session's rolled-up agent state — a state icon, the reason, and the age —
read from the shared session rollup, and each expandable to its tabs and panes so an
individual blocked pane is a jump target rather than only the session. Sessions with no agent
state SHALL render their bare name as before. The switcher MAY perform its existing `sy list`
shell-out (it runs only when the switcher opens), but it SHALL source agent state from the
same rollup the statusline uses rather than recomputing it.

#### Scenario: Blocked session shows state, reason, and age

- **WHEN** the switcher opens and session `auth-refactor` is rolled up as
  `waiting` on `needs approval` for 6 minutes
- **THEN** that session's node includes a waiting icon, the reason, and `6m`

#### Scenario: Session without agents shows a bare name

- **WHEN** the switcher opens and session `notes` has no agent state
- **THEN** its node is the plain session name with no state decoration

#### Scenario: Pinned default entry still appears

- **WHEN** the switcher opens
- **THEN** the pinned `default` entry is still present and is not required to
  carry agent state

#### Scenario: Blocked pane is reachable within its session

- **WHEN** session `auth-refactor` has a blocked agent in one of several tabs
- **THEN** that exact pane is selectable from the tree (top needs-attention zone and/or the
  session's expanded pane node), not just the session as a whole

### Requirement: Sort the switcher by urgency

The switcher SHALL order nodes so that the most action-needing targets appear first: the
needs-attention zone lists actionable panes on top, and session nodes use the rollup
precedence (`waiting > done > working > idle`, then longest age first), with stateless
sessions ordered after stated ones and dormant sessions after live ones.

#### Scenario: Longest-blocked session sorts to the top

- **WHEN** two sessions are `waiting`, one for 6 minutes and one for 1 minute
- **THEN** the 6-minute session is listed above the 1-minute session

#### Scenario: Stateless sessions sort below stated ones

- **WHEN** one session is `working` and another has no agent state
- **THEN** the `working` session is listed above the stateless session

#### Scenario: Empty rollup still yields an ordered, usable list

- **WHEN** no session has any agent state
- **THEN** the switcher still lists the sessions (pinned `default` present) in a stable order
  with no error and no needs-attention zone
