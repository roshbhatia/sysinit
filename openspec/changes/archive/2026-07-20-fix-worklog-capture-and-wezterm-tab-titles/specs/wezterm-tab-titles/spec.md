## ADDED Requirements

### Requirement: Read tab/pane data as TabInformation fields

The `format-tab-title` handler SHALL access the title, active pane, foreground
process name, and working directory as `TabInformation`/`PaneInformation`
struct fields (`tab.tab_title`, `tab.active_pane`,
`tab.active_pane.foreground_process_name`,
`tab.active_pane.current_working_dir`) and SHALL NOT call MuxTab/Pane methods
(`tab:get_title()`, `tab:active_pane()`, `pane:get_foreground_process_name()`,
`pane:get_current_working_dir()`), which the event's struct arguments do not
provide.

#### Scenario: Handler renders without erroring
- **WHEN** WezTerm fires `format-tab-title` for any tab
- **THEN** the handler returns a rendered title without raising a Lua error

#### Scenario: No MuxTab method calls remain (negative)
- **WHEN** the handler body is inspected
- **THEN** it contains no `tab:get_title()`, `tab:active_pane()`,
  `:get_foreground_process_name()`, or `:get_current_working_dir()` calls

### Requirement: Slugify the Claude pane OSC title

For a Claude Code pane, the handler SHALL source the slugifier's input from the
active pane's OSC title (`tab.active_pane.title`), falling back to
`tab.tab_title` then the cwd basename, and SHALL brand the result with the
sparkle (and the sigil process icon when available).

#### Scenario: Claude task summary becomes a slug
- **WHEN** a Claude pane's OSC title is `"Create service SLI dashboard"`
- **THEN** the tab renders the slug `sli-dashboard` branded with the sparkle

#### Scenario: No usable title falls back, not blank (negative)
- **WHEN** a freshly launched Claude pane has no OSC title yet
- **THEN** the tab shows the cwd basename with the sparkle rather than empty or
  default text

### Requirement: Preserve non-Claude tab behavior

Non-Claude tabs SHALL keep their existing rendering: an explicitly set
non-numeric `tab_title` is honored, otherwise the cwd basename (with `$HOME`
collapsed to `~`) prefixed by a sigil process icon for known non-shell
foreground processes.

#### Scenario: Shell tab shows directory
- **WHEN** a tab's foreground process is a shell with no explicit title
- **THEN** the tab shows the cwd basename

#### Scenario: Numeric auto-title is not shown verbatim (negative)
- **WHEN** the only available `tab_title` is a bare number
- **THEN** the handler does not render that number and falls back to the
  cwd/process label
