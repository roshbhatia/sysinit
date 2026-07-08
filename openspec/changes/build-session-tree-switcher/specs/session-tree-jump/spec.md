## ADDED Requirements

### Requirement: The picker opens in fuzzy filter mode

The picker SHALL open in fuzzy mode so the user filters by typing immediately against the
embedded `session/tab/agent` path and tokens, with the needs-attention zone on top. Selection
is via Enter. (A label-jump "teleport" mode was evaluated and rejected: it is incompatible
with the in-picker quick-filter keys required below, because bare-letter label selection would
bypass the key-table pop and leak the table into normal typing.)

#### Scenario: Opens ready to filter with worst on top

- **WHEN** the user presses `SUPER+s`
- **THEN** the picker opens in fuzzy mode with the needs-attention panes listed first

#### Scenario: Typing narrows by path

- **WHEN** the user types `sysinit/tests/codex`
- **THEN** the list narrows to that pane and Enter jumps to it

#### Scenario: A no-match query stays cancelable

- **WHEN** the user types a query no row matches
- **THEN** the list is empty and Esc cancels the picker cleanly with no error

### Requirement: In-picker quick-filter keys scope the view

The picker SHALL bind Ctrl keys that re-scope the view without leaving it: `Ctrl+B` (blocked /
actionable panes), `Ctrl+G` (all agent panes), `Ctrl+D` (dormant sessions), `Ctrl+A` (all —
clear the filter). These SHALL be implemented via a key table activated before the selector
whose entries also include Enter and Escape so the table is always popped on close and never
leaks into normal typing. Filter keys SHALL use Ctrl so they never collide with fuzzy typing.
An empty filtered view SHALL fall back to the full tree so the picker never opens blank.

#### Scenario: Ctrl+B scopes to blocked panes

- **WHEN** the user presses `Ctrl+B` in the open picker
- **THEN** the picker reopens listing only the actionable (rank ≥ working) panes

#### Scenario: Ctrl+A clears back to the full tree

- **WHEN** a filter is active and the user presses `Ctrl+A`
- **THEN** the picker reopens showing the needs-attention zone and full tree

#### Scenario: Closing pops the key table

- **WHEN** the user presses Enter or Escape to close the picker
- **THEN** the `session_tree_actions` key table is popped and normal typing is unaffected

#### Scenario: A filter with no matches does not open blank

- **WHEN** the user presses `Ctrl+B` and nothing is currently blocked
- **THEN** the picker falls back to the full tree rather than opening an empty list
