## ADDED Requirements

### Requirement: Roll per-pane state up to one state per session

A WezTerm-side helper SHALL produce a map keyed by seshy session name
(= WezTerm workspace) where each value is a single rolled-up state for that
session. For each live pane it SHALL read the `agent_state` user-var when
present; when absent it SHALL fall back to `agent-deck`'s scraped status for
that pane (without a reason or age). The helper SHALL be a pure in-memory walk
of live panes suitable for invocation on every `update-status` tick and MUST NOT
shell out (no `sy list`, no fs reads) on that path.

Panes whose pane id is no longer live SHALL NOT contribute, and the helper MUST
NOT require any stale-entry pruning of its own — user-var-sourced state is
discarded by WezTerm when the pane closes.

#### Scenario: Hooked pane contributes user-var state

- **WHEN** a live pane has an `agent_state` user-var decoding to
  `waiting|needs approval|...|claude`
- **THEN** that pane contributes `waiting` with reason `needs approval` and an
  age derived from its `since` timestamp

#### Scenario: Hookless pane falls back to agent-deck

- **WHEN** a live pane sets no `agent_state` user-var but `agent-deck` classifies
  it as `working`
- **THEN** that pane contributes `working` with no reason and no age

#### Scenario: Closed pane contributes nothing

- **WHEN** a pane that previously emitted `agent_state` has been closed
- **THEN** it does not appear in any session's rollup
- **AND** no pruning step is required to achieve this

### Requirement: Reduce multiple panes per session by worst-wins

When a session contains multiple agent panes, the helper SHALL reduce them to a
single state using the precedence `waiting > done > working > idle`. The reason
and age of the rolled-up state SHALL come from the pane holding the winning
state; on a tie within the winning status, the oldest `since` (longest-running)
pane SHALL provide the reason and age.

#### Scenario: A waiting pane outranks working siblings

- **WHEN** a session has one pane `waiting` and two panes `working`
- **THEN** the session's rolled-up state is `waiting`
- **AND** the reason and age are taken from the waiting pane

#### Scenario: Oldest pane wins a tie

- **WHEN** a session has two `waiting` panes with different `since` timestamps
- **THEN** the rolled-up age reflects the older `since`

#### Scenario: Session with no agent panes is absent

- **WHEN** a session's panes set no `agent_state` and `agent-deck` classifies
  none of them as an agent
- **THEN** that session does not appear in the rollup map (it has no agent state)

### Requirement: Tolerate malformed state without crashing

The helper SHALL treat a missing, non-decodable, or wrong-arity `agent_state`
value as "no user-var state" for that pane and fall back per the rules above,
never raising an error that breaks `update-status` rendering.

#### Scenario: Garbled user-var degrades to fallback

- **WHEN** a pane's `agent_state` user-var is not valid base64 or does not split
  into four fields
- **THEN** the helper ignores it and applies the `agent-deck` fallback for that
  pane
- **AND** rendering of the status bar continues normally
