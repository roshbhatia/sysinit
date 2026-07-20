## ADDED Requirements

### Requirement: Launch Claude teammates as native WezTerm panes via control mode

A Nix-generated `claude-team` command SHALL start a Claude Code session whose
teammates render as native WezTerm tabs/panes. It SHALL do so by attaching a
dedicated tmux session in WezTerm control mode (`tmux -CC`) on an isolated socket
and running `claude` inside it with teammate tmux mode forced. The session name
SHALL be derived from the current repository so that re-invoking the command in
the same repository attaches to the existing session instead of creating a
duplicate. The command SHALL require no manual tmux knowledge from the user.

#### Scenario: First invocation opens a control-mode team session

- **WHEN** the user runs `claude-team` from a WezTerm pane in a repository with
  no existing team session for that repository
- **THEN** a new control-mode tmux session starts on the dedicated socket
- **AND** `claude` runs inside it with teammate tmux mode forced
- **AND** teammates the lead spawns appear as native WezTerm tabs/panes

#### Scenario: Re-invocation attaches instead of duplicating

- **WHEN** the user runs `claude-team` again in the same repository while its team
  session is still alive
- **THEN** the command attaches to the existing session
- **AND** no second tmux session for that repository is created

#### Scenario: Invoked outside WezTerm

- **WHEN** the user runs `claude-team` from a terminal that is not WezTerm (no
  `WEZTERM_PANE`)
- **THEN** the command SHALL report that it needs WezTerm for the native-pane
  experience and exit non-zero without starting a control-mode session

#### Scenario: tmux is unavailable

- **WHEN** `claude-team` runs on a host where `tmux` is not on `PATH`
- **THEN** the command SHALL fail with a clear message naming the missing
  dependency and MUST NOT fall back to a broken half-configured session

### Requirement: Isolate the teammate tmux profile from the user's tmux

The teammate workspace SHALL use a dedicated tmux socket and a Nix-generated tmux
configuration that is separate from the user's interactive tmux setup. The
generated configuration SHALL disable the tmux status bar (WezTerm draws the tab
bar in control mode) and SHALL NOT alter, read, or depend on the user's normal
tmux sessions, sockets, or keybindings. The user SHALL NOT be expected to edit
this configuration by hand.

#### Scenario: Dedicated socket keeps sessions separate

- **WHEN** the user has interactive tmux sessions running on the default socket
  and then runs `claude-team`
- **THEN** the team session is created on the dedicated socket
- **AND** the user's default-socket sessions are neither listed nor modified

#### Scenario: Status bar is suppressed for control mode

- **WHEN** a team session is attached in control mode
- **THEN** the tmux status bar is off so WezTerm's native tab bar is the only tab
  surface shown

#### Scenario: User's tmux config is untouched

- **WHEN** the teammate tmux profile is generated and used
- **THEN** the user's hand-managed tmux configuration is not sourced or mutated
- **AND** removing the feature leaves the user's tmux setup byte-identical

### Requirement: Force deterministic tmux teammate mode

Claude Code's teammate display mode SHALL be set explicitly to `tmux` rather than
left to `auto`, so that teammates always render through the control-mode tmux
path when launched via `claude-team` and never fall back to the degraded
tmux-rendered-in-one-pane layout that `auto` selects outside a control-mode
session.

#### Scenario: Mode is set explicitly in rendered settings

- **WHEN** the Claude settings are rendered by the Nix configuration
- **THEN** the teammate display mode key is present and set to `tmux`
- **AND** the existing `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` enablement remains
  present and unchanged

#### Scenario: Ambient-tmux assumption fails

- **WHEN** live verification shows `claude --teammate-mode tmux` spawns teammates
  in a fresh tmux server instead of the ambient control-mode session
- **THEN** the launcher requirement is treated as unmet and the change is
  re-scoped before shipping, rather than shipping a launcher that shows no
  teammates
