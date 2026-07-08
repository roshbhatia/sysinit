## ADDED Requirements

### Requirement: Claude Code configured via programs.claude-code
The system SHALL configure the Claude Code CLI using the native Home Manager `programs.claude-code` module rather than raw `xdg.configFile` / `home.file` entries.

#### Scenario: settings.json is generated
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/settings.json` exists and contains the expected JSON structure (hooks, model, permissions)

#### Scenario: CLAUDE.md memory is populated
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/CLAUDE.md` exists and contains the output of `makeInstructions`

### Requirement: Agents installed to plural path
The system SHALL install subagent markdown files to `.claude/agents/` (plural) via `programs.claude-code.agents`.

#### Scenario: Oracle agent is present
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/agents/oracle.md` exists with valid YAML frontmatter

#### Scenario: Librarian agent is present
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/agents/librarian.md` exists with valid YAML frontmatter

#### Scenario: Old singular path is absent
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/agent/` directory does not exist (native module uses plural)

### Requirement: Hook script installed via programs.claude-code.hooks
The system SHALL install the `append_agentsmd_context` hook via `programs.claude-code.hooks` rather than `xdg.dataFile`.

#### Scenario: Hook is present and executable
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/hooks/append_agentsmd_context` exists and is executable

### Requirement: Skills installed via programs.claude-code.skillsDir
The system SHALL configure `programs.claude-code.skillsDir` to point to the existing `skills/` directory.

#### Scenario: Shell-scripting skill is present
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/skills/shell-script-authoring/SKILL.md` exists

### Requirement: MCP integration enabled
The system SHALL set `programs.claude-code.enableMcpIntegration = true` so that `programs.mcp.servers` are consumed automatically.

#### Scenario: MCP servers appear in settings
- **WHEN** home-manager builds the configuration
- **THEN** `~/.claude/settings.json` (or `.mcp.json`) contains the MCP server definitions from `programs.mcp.servers`
