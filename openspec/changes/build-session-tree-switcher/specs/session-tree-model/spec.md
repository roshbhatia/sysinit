## ADDED Requirements

### Requirement: Build a workspace→tab→pane tree in a single mux walk

The system SHALL build a session tree from ONE traversal of the live mux
(`wezterm.mux.all_windows()` → `window:tabs()` → `tab:panes_with_info()`), grouping
panes under their tab and workspace. Each pane node SHALL be decorated with its
`agent_state` user-var (status, agent, reason, since) when present, reusing the same
parse the existing agent rollup uses. The walk SHALL be best-effort: every mux call
`pcall`-guarded so a since-closed pane or a missing field degrades that node rather than
aborting the walk.

#### Scenario: Nested structure across workspaces

- **WHEN** two live workspaces each hold multiple tabs and panes
- **THEN** the tree contains both workspaces, each with its tabs, each tab with its panes,
  in a nested structure

#### Scenario: Agent pane is decorated with its state

- **WHEN** a pane has an `agent_state` user-var of `waiting` on `needs approval`
- **THEN** that pane node carries the waiting status, agent, reason, and since

#### Scenario: A mux call failing degrades one node, not the walk

- **WHEN** a pane closes mid-walk so a mux call for it errors
- **THEN** that pane node is omitted or rendered without its lost field and the rest of the
  tree still builds, with no raised error

### Requirement: Merge dormant seshy sessions as leaf nodes

The system SHALL include seshy sessions that appear in `sy list` but are not present as a
live workspace, as dormant leaf nodes flagged for switch-and-restore. The pinned `default`
home-base entry SHALL always be present. When `sy list` errors or returns only its header,
the tree SHALL still return the live workspaces and the pinned `default`.

#### Scenario: Dormant session becomes a leaf

- **WHEN** session `infra` is in `sy list` but has no live workspace
- **THEN** the tree includes `infra` as a dormant leaf marked for restore

#### Scenario: sy list unavailable still yields a usable tree

- **WHEN** the `sy` binary is missing or `sy list` errors
- **THEN** the tree still contains the live workspaces and the pinned `default` entry, with
  no dormant leaves and no error
