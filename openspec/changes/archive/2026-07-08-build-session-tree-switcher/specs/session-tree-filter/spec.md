## ADDED Requirements

### Requirement: Node labels embed a path and tokens for hierarchical filtering

Every node label SHALL embed, as matchable text, its full `session/tab/agent` slash-path
plus quick-filter tokens (the status word, agent name, and repo where known). Because
WezTerm's fuzzy matcher matches against the label text, this SHALL let a `/`-mode query narrow
the flat list hierarchically: a session name to that whole subtree, a `session/tab` prefix to
that tab, and a full `session/tab/agent` path to the exact pane; a bare token (e.g. an agent
name or a status word) SHALL narrow to that class across the tree.

#### Scenario: Full path filters to one pane

- **WHEN** the user enters fuzzy mode and types `sysinit/tests/codex`
- **THEN** the list narrows to the codex pane in the `tests` tab of the `sysinit` session

#### Scenario: A bare token filters to a class

- **WHEN** the user types `waiting`
- **THEN** the list narrows to the panes whose status is `waiting`

#### Scenario: A query matching nothing yields an empty, cancelable list

- **WHEN** the user types a query no node matches
- **THEN** the list is empty and `Esc` cancels the picker cleanly with no error

### Requirement: Rows are self-describing so filtering survives tree flattening

Each leaf row SHALL contain its complete ancestor path so that filtering by an ancestor name
keeps the leaf even after non-matching parent rows are filtered out; the indentation SHALL be
treated as decoration for the unfiltered view only. A row missing optional git metadata
(branch/dirty) SHALL still be filterable by its path and tokens.

#### Scenario: Filtering by an ancestor keeps the descendant

- **WHEN** the user filters by `sysinit` and the parent `sysinit` row is dropped by the match
- **THEN** the descendant pane rows still appear because each embeds `sysinit` in its path

#### Scenario: Missing git metadata does not break filtering

- **WHEN** a pane node has no branch/dirty info available in-memory
- **THEN** that row still matches its `session/tab/agent` path and tokens
