## ADDED Requirements

### Requirement: Statusline shows the active workspace

The tabline statusline SHALL render the active workspace name — as reported by
`wezterm.mux.get_active_workspace()` — in a dedicated right-side section
(`tabline_x`), without displacing the existing `mode`/`locked`/`domain`/
`agent_status`/`hostname` sections.

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
