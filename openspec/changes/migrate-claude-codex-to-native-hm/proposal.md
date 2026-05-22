## Why

The custom `config/claude.nix` and `config/codex.nix` hand-wire configuration files using `xdg.configFile` and `home.file`, re-implementing logic that Home Manager's native `programs.claude-code` and `programs.codex` modules already provide and maintain upstream. Migrating reduces local maintenance surface and unlocks native features (version-adaptive paths, plugin support, LSP, commands, rules) that the current approach doesn't support.

## What Changes

- Replace `config/claude.nix` with `programs.claude-code` native module configuration
  - Migrate `xdg.configFile."claude/claude_desktop_config.json"` → `programs.claude-code.settings`
  - Migrate `xdg.configFile."claude/CLAUDE.md"` → `programs.claude-code.memory.text`
  - Migrate `home.file.".claude/agent/*.md"` → `programs.claude-code.agents`
  - Migrate `xdg.dataFile."claude/hooks/..."` → `programs.claude-code.hooks`
  - Migrate skills installation → `programs.claude-code.skillsDir` (pointing to existing `skills/` directory)
  - Enable `programs.claude-code.enableMcpIntegration = true` to consume `programs.mcp.servers`
- Replace `config/codex.nix` with `programs.codex` native module configuration
  - Migrate `xdg.configFile."codex/config.toml"` → `programs.codex.settings`
  - Migrate `xdg.configFile."codex/AGENTS.md"` → `programs.codex.custom-instructions`
  - Enable `programs.codex.enableMcpIntegration = true` to consume `programs.mcp.servers`
- Introduce `programs.mcp` as the shared MCP source of truth for claude-code and codex
  - MCP server definitions currently in `mcp.nix` move to `programs.mcp.servers`
  - `lib/mcp.nix` formatters for gemini, amp, cursor, goose, crush, opencode, copilot remain unchanged
- **No changes** to: `gemini.nix`, `amp.nix`, `cursor.nix`, `goose.nix`, `crush.nix`, `opencode.nix`, `pi.nix`, `copilot-cli.nix`, `lib/mcp.nix`, `instructions.nix`, `skills.nix`, `subagents/`

## Capabilities

### New Capabilities

- `native-claude-code-config`: Configuration of Claude Code CLI via `programs.claude-code`, covering settings, memory, agents, hooks, skills, and MCP integration
- `native-codex-config`: Configuration of Codex CLI via `programs.codex`, covering settings, custom-instructions, skills, and MCP integration
- `shared-mcp-source`: `programs.mcp.servers` as the canonical MCP server definition consumed by both claude-code and codex natively

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- `modules/home/programs/llm/config/claude.nix` — rewritten
- `modules/home/programs/llm/config/codex.nix` — rewritten
- `modules/home/programs/llm/mcp.nix` — MCP server definitions extracted to `programs.mcp`; file may shrink or be removed if no non-native tools need it directly
- `modules/home/programs/llm/default.nix` — may need to import `programs.mcp` module or enable it
- Home Manager must have `programs.claude-code` and `programs.codex` modules available (requires home-manager master / recent release)
- Directory rename: `.claude/agent/` → `.claude/agents/` (plural) — Claude Code will no longer see agents in the old path after migration
