## ADDED Requirements

### Requirement: Namespace the cross-surface state file per pane under tmux

When the emitter runs inside tmux (`$TMUX` set), the per-pane JSON state file it
writes SHALL be keyed so that two teammates in different tmux panes do not
overwrite each other. Because every window of a control-mode tmux session
inherits a single stale `WEZTERM_PANE` value, keying the file on `WEZTERM_PANE`
alone collapses all teammates onto one file. The emitter SHALL instead include
the tmux pane id (`TMUX_PANE`) in the state file name when `$TMUX` is set, and
SHALL keep the current `WEZTERM_PANE`-only name when not in tmux. The OSC 1337
`SetUserVar` emit SHALL be unchanged in all cases, because control mode already
routes it to the correct native WezTerm pane regardless of the `WEZTERM_PANE`
value.

#### Scenario: Two teammates write distinct state files

- **WHEN** the emitter runs in two different tmux panes of the same control-mode
  session, each stamping a different `agent_state`
- **THEN** each writes a distinct per-pane JSON file keyed by its `TMUX_PANE`
- **AND** neither teammate's state overwrites the other's

#### Scenario: Non-tmux emission keeps the existing file name

- **WHEN** the emitter runs in a WezTerm pane with no `$TMUX`
- **THEN** the state file name is the existing `WEZTERM_PANE`-keyed name
- **AND** existing out-of-WezTerm consumers see no path change

#### Scenario: OSC emit is unchanged under tmux

- **WHEN** the emitter runs inside a control-mode tmux pane
- **THEN** it still writes the same OSC 1337 `SetUserVar=agent_state=<base64>` to
  its controlling tty
- **AND** the file-keying change does not alter, wrap, or suppress that emit

#### Scenario: TMUX_PANE missing while $TMUX is set

- **WHEN** `$TMUX` is set but `TMUX_PANE` is empty or unset
- **THEN** the emitter SHALL fall back to the `WEZTERM_PANE`-keyed name rather
  than writing a file with an empty pane segment, and MUST still exit 0
