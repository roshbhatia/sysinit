## ADDED Requirements

### Requirement: Jump to the worst blocked pane

A WezTerm keybind (`SUPER+g`) SHALL activate the pane returned by
`worst_agent_pane()` across all workspaces: switching to that pane's workspace
if it differs from the active one, activating its tab, and activating the pane
itself, so the user lands directly on the agent most in need of attention. The
jump SHALL operate on the shared rollup and MUST NOT require the target pane to
be in the active workspace.

#### Scenario: Jump crosses workspaces to the waiting pane

- **WHEN** the worst blocked pane is a `waiting` pane in a different workspace
  and the user presses `SUPER+g`
- **THEN** WezTerm switches to that workspace, activates the pane's tab, and
  activates the pane

#### Scenario: Jump reaches a throwaway tab in the same session

- **WHEN** the worst blocked pane is in another tab of the active session
- **THEN** `SUPER+g` activates that tab and pane without changing workspace

#### Scenario: Nothing blocked is a no-op

- **WHEN** the user presses `SUPER+g` and no pane holds actionable state
- **THEN** the binding does nothing and surfaces no error

### Requirement: Pick from all blocked panes

A second keybind (`SUPER+SHIFT+g`) SHALL open an `InputSelector` listing every
currently blocked pane with enough context to disambiguate — session, tab,
agent, reason, and age — ordered by the rollup precedence, and activating the
chosen pane (workspace + tab + pane) on selection.

#### Scenario: Selector lists each blocked pane with context

- **WHEN** three panes across two sessions are blocked and the user presses
  `SUPER+SHIFT+g`
- **THEN** the selector shows three rows, each naming its session, tab, agent,
  reason, and age
- **AND** choosing a row activates that pane's workspace, tab, and pane

#### Scenario: Empty selector when nothing is blocked

- **WHEN** the user presses `SUPER+SHIFT+g` and no pane is blocked
- **THEN** the selector opens empty or does not open, and no pane is activated
- **AND** no error is surfaced

#### Scenario: A row referencing a now-closed pane is skipped

- **WHEN** a selected pane has closed between the selector opening and the
  choice
- **THEN** activation fails gracefully without raising an error
