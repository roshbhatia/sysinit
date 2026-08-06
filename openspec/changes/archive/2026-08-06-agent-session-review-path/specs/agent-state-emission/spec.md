## ADDED Requirements

### Requirement: Liveness is the reader's rule, stated once

A state file is evidence that a pane held a state, not that the pane still
exists. Every reader SHALL intersect the state files with the live pane set
before drawing a conclusion, and SHALL treat a file naming a pane id that no
longer exists as absent.

A reader that cannot determine the live pane set SHALL skip the agent-state
input entirely rather than treat every file as live. Assuming liveness turns one
crashed session into a permanent blocker on every surface that reads the bus.

This rule already governs the WezTerm statusline, which prunes against
`wezterm.mux.all_windows()`. It is stated here because the readiness report is a
second reader outside WezTerm's Lua, and a per-reader reimplementation is how
two surfaces come to disagree.

#### Scenario: A reader ignores a dead pane's file

- **POLARITY** positive
- **WHEN** a state file names a pane id absent from the live pane set
- **THEN** the reader treats it as absent

#### Scenario: A reader that cannot see the pane set skips the input

- **POLARITY** negative
- **WHEN** the live pane set cannot be determined
- **THEN** the reader skips the agent-state input and says so
- **AND** it does not report every state file as a live agent
