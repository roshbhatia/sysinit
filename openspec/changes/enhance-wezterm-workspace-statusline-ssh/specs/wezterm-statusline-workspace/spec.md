## ADDED Requirements

### Requirement: Statusline shows the active workspace

The tabline statusline SHALL render the active workspace name — as reported by
`wezterm.mux.get_active_workspace()` — in the left status immediately right of
the `domain` section (`tabline_b = { "domain", "workspace" }`), so the
connection context and active session read left-to-right, without displacing the
existing `mode`/`locked`/`agent_status` sections.

#### Scenario: Seshy session name is shown

- **WHEN** the active workspace is a seshy session (e.g. `inf-1785`)
- **THEN** the tabline renders `inf-1785` in its workspace section

#### Scenario: Default workspace is shown verbatim

- **WHEN** the active workspace is `default`
- **THEN** the tabline renders `default` rather than blanking the section

#### Scenario: Workspace section does not break tab titles (negative)

- **WHEN** the workspace indicator is added while `tabs_enabled = false` keeps the
  custom `format-tab-title` handler active
- **THEN** the custom per-tab titles still render and the workspace section does
  not overwrite or suppress them

### Requirement: Statusline omits the right-edge hostname

The tabline statusline SHALL NOT render the `hostname` component on the right
edge (`tabline_z = {}`). The connection context already appears in the `domain`
section (`tabline_b`), so the hostname is redundant.

#### Scenario: Hostname is absent from the right edge

- **WHEN** the statusline renders in any workspace, local or over SSH
- **THEN** no hostname is shown in the `tabline_z` section

#### Scenario: Domain context is still visible (negative)

- **WHEN** the active pane is connected to an `ssh:<host>` domain
- **THEN** the connection context is still conveyed by the `domain` section
  rather than being lost with the removed hostname
