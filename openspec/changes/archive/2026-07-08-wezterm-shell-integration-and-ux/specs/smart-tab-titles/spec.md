## ADDED Requirements

### Requirement: Tab title shows cwd and foreground process
WezTerm SHALL register a `format-tab-title` event handler that displays the tab title as `<basename(cwd)> (<process>)` where `cwd` is the current working directory of the active pane and `process` is the name of the foreground process.

#### Scenario: Active pane with a running process
- **WHEN** a tab's active pane has a foreground process (e.g. `nvim`)
- **THEN** the tab title reads `<dir> (<process>)`, e.g. `sysinit (nvim)`

#### Scenario: Active pane at shell prompt
- **WHEN** a tab's active pane foreground process is the shell itself (`zsh`)
- **THEN** the tab title reads `<dir>`, omitting the process name

#### Scenario: Fallback for unknown cwd
- **WHEN** cwd cannot be determined (new tab before first prompt)
- **THEN** the tab title falls back to the tab index (WezTerm default)

### Requirement: User-set tab title takes precedence
When the user has explicitly set a tab title via the rename binding, that title SHALL override the dynamic title.

#### Scenario: Renamed tab stays renamed
- **WHEN** the user renames a tab via `CTRL+SHIFT+R`
- **THEN** the user-supplied title persists and is not overwritten by the `format-tab-title` handler
