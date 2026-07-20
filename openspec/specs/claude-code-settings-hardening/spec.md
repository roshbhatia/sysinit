# claude-code-settings-hardening Specification

## Purpose
TBD - created by archiving change refine-harness-configs-and-refresh-pi. Update Purpose after archive.
## Requirements
### Requirement: Slack send tools are mechanically gated under skip-permissions

Because `dangerouslySkipPermissions = true` bypasses `permissions.ask`, the
Claude Code config MUST gate the Slack send tools with a `PreToolUse` hook
rather than a `permissions.ask` entry. The hook MUST deny the three
`slack_send_*` MCP tools and MUST return a message that tells the agent to have
the human send the Slack message. The inert `permissions.ask` entry MUST be
removed.

#### Scenario: Slack send is denied under skip

- **WHEN** a Claude Code session runs with `dangerouslySkipPermissions = true`
  and the agent calls `mcp__claude_ai_Slack__slack_send_message`
- **THEN** the `PreToolUse` hook returns a deny decision
- **AND** the returned message instructs the agent to ask the human to send

#### Scenario: Non-Slack tools are unaffected

- **WHEN** the agent calls any tool other than the three `slack_send_*` tools
- **THEN** the Slack guard hook takes no action and the tool proceeds

#### Scenario: Dead ask entry is gone

- **WHEN** the rendered Claude settings are inspected
- **THEN** `permissions.ask` no longer lists the Slack send tools

### Requirement: High-value Claude Code settings are set explicitly

The Claude Code config MUST set the following documented settings:
`fileCheckpointingEnabled = true`, `effortLevel = "high"`,
`fallbackModel = ["claude-sonnet-5"]`, `alwaysThinkingEnabled = true`,
`autoMemoryEnabled = true`, and `DISABLE_AUTOUPDATER = "1"` in `env`.

#### Scenario: Settings render in the config

- **WHEN** home-manager builds the Claude Code settings
- **THEN** each of the six settings above is present with the stated value

#### Scenario: Nix owns updates

- **WHEN** a Claude Code session starts
- **THEN** the in-place auto-updater does not run, matching the update-disabled
  posture of every other harness in this repo

### Requirement: A custom output style encodes the STE communication rules

The Claude Code config MUST ship a custom output style whose content encodes the
Simplified Technical English and ADHD-shaped-output rules from the shared
`Communication` section, and MUST select it via the `outputStyle` setting.

#### Scenario: Output style is active

- **WHEN** a Claude Code session starts
- **THEN** the selected output style is the STE style shipped by this config
- **AND** the style file is generated declaratively by home-manager

