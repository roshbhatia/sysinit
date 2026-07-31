## ADDED Requirements

### Requirement: The menu bar names the worst blocked session

A sketchybar widget SHALL read the per-pane agent state bus and display the
worst agent state across every live pane. It SHALL use the worst-wins ordering
that `agent-session-rollup` already owns: `waiting` beats `done`, `done` beats
`working`, and `working` beats `idle`. This requirement does not redefine that
ordering; it names the widget as a second consumer of it.

The widget's source is narrower than the statusline's. The statusline falls
back to agent-deck scraping for a pane that writes no state file; the widget
reads only the state files. The two surfaces therefore disagree for a pane
whose harness is deferred or surfaceless. That divergence MUST be stated in the
widget's own documentation, so a reader does not treat an empty menu bar as
"no agent running".

The widget SHALL name the session that owns the worst state. When no pane
holds a state above `idle`, the widget SHALL render nothing.

#### Scenario: A blocked session is named

- **POLARITY** positive
- **WHEN** one pane is `waiting` and two panes are `working`
- **THEN** the widget shows the `waiting` icon
- **AND** it names the session that owns the waiting pane

#### Scenario: Nothing to report renders nothing

- **POLARITY** negative
- **WHEN** every live pane is `idle` or no state file exists
- **THEN** the widget renders no text and no icon
- **AND** it occupies no bar width

#### Scenario: A scraped-only pane is invisible to the widget

- **POLARITY** negative
- **WHEN** the only running agent belongs to a deferred or surfaceless harness,
  so the statusline names it through agent-deck scraping and no state file
  exists
- **THEN** the widget renders nothing while the statusline names that session
- **AND** the divergence is documented rather than treated as a defect

### Requirement: The widget reads the bus and never the harness

The widget SHALL read only `$XDG_STATE_HOME/agents/panes/*.json`. It MUST NOT
invoke a harness binary, must not shell out to git, and must not call the
WezTerm CLI on its refresh path.

The widget SHALL ignore a state file whose schema version it does not
understand, a file that declares no version at all, and a file that does not
parse.

Because the widget may not check pane liveness, it cannot prune a stale entry
itself. It therefore requires the collection step from
`harden-agent-shell-terminal`. Without collection, a pane killed while its
agent was blocked leaves a `waiting` file that no transition will ever
overwrite, and the widget would name a dead session forever.

#### Scenario: A refresh does no process spawning

- **POLARITY** positive
- **WHEN** the widget refreshes
- **THEN** it reads the state directory and nothing else

#### Scenario: An unreadable file is skipped

- **POLARITY** negative
- **WHEN** a state file is truncated, is not valid JSON, declares a schema
  version the widget does not understand, or declares no version at all
- **THEN** the widget skips that file
- **AND** it still reports the worst state across the remaining files

#### Scenario: A killed blocked pane does not badge forever

- **POLARITY** negative
- **WHEN** a pane is killed while its agent state is `waiting`, so no
  transition will ever overwrite its state file
- **THEN** collection removes the file and the widget stops naming it
- **AND** the widget is not shipped before collection exists

### Requirement: Clicking the widget raises the pane

Clicking the widget SHALL invoke `agent-focus` for the pane that owns the
displayed state, reusing the executable the notification click handler uses.

#### Scenario: A click routes to the pane

- **POLARITY** positive
- **WHEN** the human clicks the widget while it names a waiting pane
- **THEN** `agent-focus` runs with that pane id and its session name

#### Scenario: A click on a stale pane degrades

- **POLARITY** negative
- **WHEN** the named pane no longer exists
- **THEN** `agent-focus` falls back to another pane in the session, or raises
  WezTerm
- **AND** no error is surfaced to the human
