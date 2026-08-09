## MODIFIED Requirements

### Requirement: Roll per-pane state up to one state per session

A WezTerm-side helper SHALL produce a map keyed by WezTerm workspace, where each
value is a single rolled-up state for that workspace. For each live pane it
SHALL read the `agent_state` user-var when present; when absent it SHALL fall
back to `agent-deck`'s scraped status for that pane (without a reason or age).

The key is the workspace and NOT the session name, and the two are no longer the
same string. A session is now a zmx session, named for a seshy session, and
several of them can live in one workspace. The previous wording made them equal
by definition and cannot survive that.

Each rolled-up entry SHALL therefore also carry the distinct session names of
the panes in it, in first-seen order, so a group named for a workspace still
says which sessions are inside it. The names live on the collapsed entry and not
only on the flat per-pane array, because two of the helper's three consumers
take the first return value alone and would never see a field added to the
second.

The helper MUST NOT shell out on this path: no `sy list`, no process spawn. It
MAY read one state-record file per pane that already holds an agent state, which
is where the session name comes from, and that read SHALL be throttled by the
existing once-a-second rollup cache. The previous wording forbade file reads
outright; that prohibition existed to keep `update-status` cheap, and a cached
open per agent pane meets the same bar. Panes with no agent state are skipped
before the read, so the cost scales with agent panes and not with all panes.

Panes whose pane id is no longer live SHALL NOT contribute, and the helper MUST
NOT require any stale-entry pruning of its own.

#### Scenario: Hooked pane contributes user-var state

- **POLARITY** positive
- **WHEN** a live pane has an `agent_state` user-var decoding to
  `waiting|needs approval|...|claude`
- **THEN** that pane contributes `waiting` with reason `needs approval` and an
  age derived from its `since` timestamp

#### Scenario: Hookless pane falls back to agent-deck

- **POLARITY** positive
- **WHEN** a live pane sets no `agent_state` user-var but `agent-deck` classifies
  it as `working`
- **THEN** that pane contributes `working` with no reason and no age

#### Scenario: Closed pane contributes nothing

- **POLARITY** negative
- **WHEN** a pane that previously emitted `agent_state` has been closed
- **THEN** it does not appear in any workspace's rollup
- **AND** no pruning step is required to achieve this

#### Scenario: Two sessions in one workspace are both named

- **POLARITY** positive
- **WHEN** one workspace holds two agent panes whose records name sessions
  `alpha` and `beta`
- **THEN** the rollup holds one entry for that workspace
- **AND** that entry names both `alpha` and `beta`

#### Scenario: A pane with no recorded session adds no name

- **POLARITY** negative
- **WHEN** an agent pane's record carries an empty session
- **THEN** it still contributes its status to the rollup
- **AND** it adds no name to the entry, rather than adding an empty one

#### Scenario: The record read stays off the per-tick path

- **POLARITY** negative
- **WHEN** `update-status` fires several times within one second
- **THEN** the helper computes once and serves the cache for the rest
- **AND** no pane record is opened more than once in that second
