## ADDED Requirements

### Requirement: WezTerm shell integration sourced in zsh
The zsh configuration SHALL source WezTerm's shell integration script (`wezterm shell-integration`) when the environment variable `TERM_PROGRAM` equals `WezTerm`, enabling OSC 133 prompt boundary markers.

#### Scenario: Integration sourced in WezTerm session
- **WHEN** a zsh session starts inside WezTerm (`$TERM_PROGRAM == "WezTerm"`)
- **THEN** `wezterm shell-integration` output is evaluated, emitting OSC 133 markers at each prompt

#### Scenario: Integration skipped outside WezTerm
- **WHEN** a zsh session starts in any other terminal or over SSH
- **THEN** the `wezterm shell-integration` source block is not executed

### Requirement: Prompt-jump keybindings
WezTerm SHALL bind `CTRL+SHIFT+Up` and `CTRL+SHIFT+Down` to `ScrollToPrompt(-1)` and `ScrollToPrompt(1)` respectively, navigating between OSC 133 prompt boundaries in the scrollback buffer.

#### Scenario: Jump to previous prompt
- **WHEN** the user presses `CTRL+SHIFT+Up`
- **THEN** the viewport scrolls to the previous shell prompt boundary

#### Scenario: Jump to next prompt
- **WHEN** the user presses `CTRL+SHIFT+Down`
- **THEN** the viewport scrolls to the next shell prompt boundary

#### Scenario: Locked mode passthrough
- **WHEN** locked mode is active and the user presses `CTRL+SHIFT+Up` or `CTRL+SHIFT+Down`
- **THEN** the raw key event is forwarded to the pane unchanged
