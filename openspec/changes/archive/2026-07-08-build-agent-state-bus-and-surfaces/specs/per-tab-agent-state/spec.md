## ADDED Requirements

### Requirement: Render per-tab agent state in the tab bar

The tab bar SHALL display, for each tab, the agent state of that tab's active
pane — a state icon (`◔` waiting, `●` working, `✔` done, `○` idle) alongside the
agent name and a short repo/cwd label. This requires per-tab rendering to be
enabled (tabline `tabs_enabled`), and the tab component SHALL read the active
pane's `agent_state` user-var. Tabs whose active pane holds no agent state SHALL
render their ordinary title without a state icon. Because WezTerm tab titles are
natively click-to-switch, this indicator SHALL be the clickable affordance for
selecting the tab that needs attention.

#### Scenario: Waiting tab shows the waiting icon

- **WHEN** a tab's active pane has `agent_state` decoding to `waiting`
- **THEN** that tab's title shows the waiting icon plus the agent name and short
  repo label

#### Scenario: Non-agent tab shows a plain title

- **WHEN** a tab's active pane holds no `agent_state` user-var
- **THEN** that tab renders its ordinary title with no state icon

#### Scenario: Malformed user-var falls back to a plain title

- **WHEN** a tab's active-pane `agent_state` is unparsable or wrong-arity
- **THEN** the tab renders its ordinary title without a state icon
- **AND** tab-bar rendering continues without error

### Requirement: Preserve existing tab-bar placement and behavior

Enabling per-tab rendering SHALL preserve the existing tab-bar placement
(`tab_bar_at_bottom`) and MUST NOT remove the existing statusline sections
(mode/locked indicator, agent status, workspace/domain). The per-tab indicator
is additive to the current tabline configuration.

#### Scenario: Statusline sections remain after enabling tabs

- **WHEN** per-tab rendering is enabled
- **THEN** the mode/locked-indicator, agent-status, and workspace/domain
  sections still render as before
- **AND** the tab bar stays at the bottom

#### Scenario: Enabling tabs does not regress the switcher or jump

- **WHEN** per-tab rendering is enabled
- **THEN** the `SUPER+s` switcher and `SUPER+g` jump continue to function
  unchanged
