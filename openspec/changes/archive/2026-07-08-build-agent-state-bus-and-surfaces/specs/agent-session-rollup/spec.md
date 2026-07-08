## ADDED Requirements

### Requirement: Retain per-pane detail alongside the session rollup

The rollup helper SHALL, in addition to the one-state-per-session map, expose
the per-pane records it visited, each carrying at least the pane id, window id,
tab id, workspace/session, repo, branch, agent, status, reason, and `since`.
This per-pane view SHALL be derived from the same single walk of live panes as
the session rollup (no second traversal, no shell-out on the render path) and
SHALL only include panes that currently hold agent state (user-var or
agent-deck fallback).

#### Scenario: Per-pane records accompany the session map

- **WHEN** the rollup runs over a session with two agent panes
- **THEN** the helper returns both the reduced session state and two per-pane
  records
- **AND** each per-pane record names its pane id, tab id, and status

#### Scenario: Panes without agent state are omitted from the per-pane view

- **WHEN** a pane holds no `agent_state` user-var and agent-deck does not
  classify it as an agent
- **THEN** that pane appears in neither the session rollup nor the per-pane view

#### Scenario: Stale pane id contributes no per-pane record

- **WHEN** a pane referenced by a prior tick is no longer live
- **THEN** it produces no per-pane record and requires no pruning step

### Requirement: Select the single worst blocked pane

The helper SHALL expose `worst_agent_pane()` returning the one pane the user
should jump to: the highest-ranked pane by the existing precedence
(`waiting > done > working > idle`), breaking ties by oldest `since`
(longest-running). It SHALL return a record sufficient to activate that exact
pane (pane id plus its workspace and tab) or a nil/empty result when no pane
holds actionable state.

#### Scenario: Waiting pane in a throwaway tab is selected

- **WHEN** the active session's main pane is `working` and a throwaway tab's
  pane is `waiting`
- **THEN** `worst_agent_pane()` returns the `waiting` pane's id, workspace, and
  tab

#### Scenario: Oldest waiting pane wins a tie across sessions

- **WHEN** two panes in different sessions are both `waiting` with different
  `since` timestamps
- **THEN** `worst_agent_pane()` returns the pane with the older `since`

#### Scenario: No actionable pane returns empty

- **WHEN** no live pane holds `waiting`, `done`, or `working` state
- **THEN** `worst_agent_pane()` returns a nil/empty result
- **AND** callers treat it as "nothing to jump to" without error
