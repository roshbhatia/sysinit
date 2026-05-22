## ADDED Requirements

### Requirement: Codex configured via programs.codex
The system SHALL configure the Codex CLI using the native Home Manager `programs.codex` module rather than raw `xdg.configFile` entries.

#### Scenario: config.toml is generated
- **WHEN** home-manager builds the configuration
- **THEN** a codex config file (`.codex/config.toml` or `~/.config/codex/config.toml` depending on XDG settings and codex version) exists and contains valid TOML

#### Scenario: AGENTS.md is populated
- **WHEN** home-manager builds the configuration
- **THEN** the codex AGENTS.md file exists and contains the output of `makeInstructions`

### Requirement: MCP integration enabled
The system SHALL set `programs.codex.enableMcpIntegration = true` so that `programs.mcp.servers` are consumed and written to the codex config.

#### Scenario: MCP servers appear in codex config
- **WHEN** home-manager builds the configuration
- **THEN** the codex config file contains `[mcp_servers]` entries matching the definitions in `programs.mcp.servers`

### Requirement: Version-adaptive file paths respected
The system SHALL rely on the native module's version detection for config file format and skills directory placement.

#### Scenario: Config format matches codex version
- **WHEN** the pinned `pkgs.codex` is >= 0.2.0
- **THEN** configuration is written as TOML to the appropriate path

#### Scenario: Skills path matches codex version
- **WHEN** the pinned `pkgs.codex` is >= 0.94.0
- **THEN** skills are installed to `~/.agents/skills/` rather than `~/.codex/skills/`
