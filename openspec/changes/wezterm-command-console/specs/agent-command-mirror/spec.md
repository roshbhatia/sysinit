## ADDED Requirements

### Requirement: A per-pane mirror pane shows agent command output live

The system SHALL provide `agent-mirror-begin`, a best-effort helper that ensures a
mirror pane exists for the calling agent pane. It SHALL create the pane with
`wezterm cli split-pane --pane-id "$WEZTERM_PANE" --bottom`, running a tail of that
pane's log. A bottom split keeps the window's full width for both panes.

`agent-mirror-begin` SHALL run `wezterm cli activate-pane --pane-id "$WEZTERM_PANE"`
immediately after creating the pane, so keyboard focus returns to the agent.

`agent-mirror-begin` SHALL record the mirror pane id under
`${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror/<agent-pane>.pane`, stamped with
the WezTerm instance identity, and SHALL discard a record whose stamp does not match.
WezTerm recycles pane ids across restarts.

`agent-mirror-begin` SHALL parse a pane id from `wezterm cli` output as the last line
and digits only. WezTerm may interleave log lines on that output, so a whole-stdout
capture yields a string that the next `wezterm cli` call rejects.

`agent-mirror-begin` SHALL always exit 0 and MUST NOT be able to prevent or alter the
command that follows it.

#### Scenario: The first command creates the mirror pane

- **POLARITY** positive
- **WHEN** `agent-mirror-begin` runs in an agent pane with no recorded mirror pane
- **THEN** it creates a bottom split running a tail of the pane's log
- **AND** it records the new pane id with the WezTerm instance stamp
- **AND** it activates the agent pane so focus does not move to the mirror

#### Scenario: WezTerm output interleaves a log line with the pane id

- **POLARITY** negative
- **WHEN** `wezterm cli split-pane` emits a plugin log line before the pane id
- **THEN** `agent-mirror-begin` extracts only the trailing digits
- **AND** the recorded pane id is usable by a later `wezterm cli` call

#### Scenario: WezTerm restarts and reassigns the recorded pane id

- **POLARITY** negative
- **WHEN** a recorded `.pane` entry carries a WezTerm instance stamp that does not
  match the current instance
- **THEN** `agent-mirror-begin` discards the record and creates a new mirror pane
- **AND** it does not write into an unrelated pane that now holds that id

#### Scenario: The helper fails outright

- **POLARITY** negative
- **WHEN** `agent-mirror-begin` cannot reach `wezterm cli`, cannot create the pane,
  or cannot write its state
- **THEN** it exits 0
- **AND** the command that follows it still runs and still returns its own exit code

### Requirement: The mirror never changes what a command does

The wrapped command SHALL run in the agent's own shell, in the agent's own working
directory, with the agent's own environment. The mirror SHALL NOT transport,
re-encode, or re-interpret the command text.

A failure of the copying stage SHALL NOT suppress the command or its output.

The agent SHALL receive the command's own exit code, including non-zero.

#### Scenario: A command's output still reaches the agent

- **POLARITY** positive
- **WHEN** the agent runs a command that writes to stdout and stderr
- **THEN** the agent receives that output
- **AND** the mirror pane shows the same output live

#### Scenario: The log path is not writable

- **POLARITY** negative
- **WHEN** the copying stage cannot write the log
- **THEN** the command still runs
- **AND** its output still reaches the agent
- **AND** the agent still receives the command's own exit code

#### Scenario: A command exits non-zero

- **POLARITY** negative
- **WHEN** the agent runs a command that exits 7
- **THEN** the agent receives exit 7, not the exit status of the copying stage

### Requirement: The command runs on a real pty so its output looks correct

The wrapped command SHALL run under `script(1)`, so it sees a real terminal and
renders as it would when run by hand.

Environment variables MUST NOT be relied on to recover colour through a pipe.
Measured with ripgrep: unforced through a pipe produced 0 escape bytes, and
`CLICOLOR_FORCE=1 FORCE_COLOR=1` also produced 0. The same command under a pty
produced 14. The wrapper cannot add `--color=always` to the owner's command, so a
pty is the only mechanism that preserves rendering.

The mirror pane SHALL receive the raw pty stream. The agent SHALL receive a copy
with ANSI escape sequences, carriage returns, and the leading end-of-transmission
and backspace bytes that `script(1)` writes removed. The stripping stage SHALL pass
its input through unchanged if it fails, because losing colour is acceptable and
losing output is not.

`agent-mirror-begin` SHALL write a header line before each command, identifying the
command and its working directory, so output from concurrent callers can be
attributed.

`agent-mirror-begin` SHALL truncate the log when it exceeds a stated size.

#### Scenario: A colour-emitting command is mirrored

- **POLARITY** positive
- **WHEN** the agent runs a command that colours its output when run by hand
- **THEN** the mirror pane shows that colour
- **AND** the agent receives the same text with the escape sequences removed

#### Scenario: The command text fails to decode

- **POLARITY** negative
- **WHEN** the decode of the encoded command yields an empty result
- **THEN** the original command runs verbatim instead
- **AND** no empty command is run
- **AND** the agent is not told that a skipped command succeeded

#### Scenario: The stripping stage fails

- **POLARITY** negative
- **WHEN** the stripping stage errors
- **THEN** it passes its input through unchanged
- **AND** the agent still receives the command's output

#### Scenario: Two subagents run commands at the same time

- **POLARITY** positive
- **WHEN** two subagents in one agent pane run commands concurrently
- **THEN** both commands run without delay
- **AND** each has written a header, so its output is attributable
- **AND** neither command is dropped, delayed, or run twice

#### Scenario: The log has grown past its limit

- **POLARITY** negative
- **WHEN** the log exceeds the stated size
- **THEN** `agent-mirror-begin` truncates it
- **AND** the tailing pane continues to follow the truncated file

### Requirement: The mirror can be disabled without restarting the session

The kill switch SHALL be the file
`${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror.disabled`. The guard and
`agent-mirror-begin` SHALL read it fresh on every command, so creating it takes
effect in an already-running agent session. Nix MUST NOT manage this path, so that
creating it can never collide with a managed file and block a later activation.

The `SYSINIT_AGENT_MIRROR` environment variable SHALL be the staged-rollout flag
only. It is read at session start. It MUST NOT be used as the in-session kill
switch, because a running process's environment cannot be changed. The rollout flag
and the kill switch MUST NOT be the same mechanism.

A set kill switch SHALL be surfaced in the statusline, beside the existing
agent-state chips, because the file is global and nothing removes it automatically.

#### Scenario: The kill switch disables the mirror mid-session

- **POLARITY** positive
- **WHEN** the owner creates the kill-switch file from another pane while an agent
  session is running
- **THEN** the session's next Bash command is not wrapped
- **AND** no mirror pane is created
- **AND** the owner does not need to restart the agent session

#### Scenario: The kill switch is left set after an incident

- **POLARITY** negative
- **WHEN** the kill-switch file remains on disk after the incident that prompted it
- **THEN** the statusline shows that the mirror is disabled
- **AND** the owner is not left with a silently inert feature

#### Scenario: The agent runs outside WezTerm

- **POLARITY** negative
- **WHEN** `WEZTERM_PANE` is unset, for example over SSH or in a nix build
- **THEN** no mirror pane is created
- **AND** the command runs exactly as it did before this change
