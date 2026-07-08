## ADDED Requirements

### Requirement: SUPER+s opens the all-in-one session tree with a needs-attention zone

`SUPER+s` SHALL open a single `InputSelector` rendering the session tree as indented rows,
led by a needs-attention zone listing the actionable panes (rank ≥ working) in urgency order
so the worst blocked pane is reachable the instant the picker opens. The binding SHALL honor
the existing `keybindings.locked_mode` passthrough (send the literal key when locked). The
pinned `default` entry SHALL remain present.

#### Scenario: Worst blocked pane is on top at open

- **WHEN** a pane is `waiting` and the user presses `SUPER+s`
- **THEN** that pane appears in the needs-attention zone at the top of the picker

#### Scenario: Locked mode passes the key through

- **WHEN** `keybindings.locked_mode` is active and `SUPER+s` is pressed
- **THEN** the picker does NOT open and the literal `SUPER+s` is sent to the pane

### Requirement: Level-aware activation dispatch

Selecting a node SHALL act according to the node kind encoded in its choice `id`: a pane
node SHALL activate that exact pane (mux tab + pane activate, plus `SwitchToWorkspace` if it
lives in another workspace); a tab node SHALL activate that tab; a live workspace node SHALL
`SwitchToWorkspace`. Activation SHALL be best-effort — a since-closed target SHALL resolve to
a no-op rather than an error.

#### Scenario: Pane node jumps to the exact pane

- **WHEN** the user selects a pane node in another workspace
- **THEN** that workspace is switched to and the exact tab and pane are activated

#### Scenario: Selecting a since-closed node no-ops

- **WHEN** the selected node's pane or tab has closed since the picker opened
- **THEN** activation silently does nothing and raises no error

### Requirement: Dormant session selection restores through the plugin

Selecting a dormant seshy leaf SHALL route through the `workspace-manager.wezterm` plugin's
own switch-and-restore path so the saved layout is restored; the system SHALL NOT hand-roll a
resurrect from the session state directory. If no plugin restore entry point is available,
the system SHALL fall back to delegating the selection to the plugin's existing switcher
rather than performing a bare layout-less `SwitchToWorkspace`.

#### Scenario: Dormant leaf restores its layout

- **WHEN** the user selects the dormant `infra` leaf
- **THEN** the `infra` workspace is switched to with its saved layout restored via the plugin

#### Scenario: No plugin restore entry point falls back safely

- **WHEN** the plugin exposes no programmatic switch-with-restore call
- **THEN** the selection is delegated to the plugin's own switcher and the user is never left
  in a bare, layout-less workspace produced by a hand-rolled switch

### Requirement: The tree subsumes and retires the separate blocked-pane picker

The `SUPER+SHIFT+g` blocked-pane picker SHALL be removed, its function absorbed by the tree's
needs-attention zone and pane nodes. `SUPER+g` (express jump to the worst pane) and
`SUPER+SHIFT+s` (ssh host picker) SHALL remain bound and unchanged.

#### Scenario: SHIFT+g no longer opens a pane picker

- **WHEN** the user presses `SUPER+SHIFT+g`
- **THEN** no blocked-pane picker opens (the binding is gone)

#### Scenario: Express jump and ssh remain intact

- **WHEN** the user presses `SUPER+g` or `SUPER+SHIFT+s`
- **THEN** the express worst-pane jump and the ssh host picker behave exactly as before
