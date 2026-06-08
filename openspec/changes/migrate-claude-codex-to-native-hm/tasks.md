## 1. Preflight

- [x] 1.1 Verify `programs.claude-code` module exists in the pinned home-manager (grep for `programs/claude-code.nix` in HM source)
- [x] 1.2 Verify `programs.codex` module exists in the pinned home-manager
- [x] 1.3 Verify `programs.mcp` module exists in the pinned home-manager
- [x] 1.4 Check `pkgs.codex` version to determine if `.agents/skills` path (>=0.94.0) or `.codex/skills` (<0.94.0) will be used

## 2. Introduce programs.mcp

- [x] 2.1 Add `programs.mcp.enable = true` and `programs.mcp.servers` block to `default.nix` (or a new `mcp-native.nix`), populated with the same server definitions currently in `mcp.nix`
- [x] 2.2 Confirm `lib/mcp.nix` still exports formatters for the remaining tools (no changes needed, just verify they still work with whatever source they use)

## 3. Migrate config/claude.nix to programs.claude-code

- [x] 3.1 Add `programs.claude-code.enable = true` and `programs.claude-code.package = pkgs.claude-code`
- [x] 3.2 Set `programs.claude-code.enableMcpIntegration = true`
- [x] 3.3 Move JSON settings (hooks, any top-level config) from the old `claudeConfig` JSON to `programs.claude-code.settings`
- [x] 3.4 Set `programs.claude-code.memory.text = llmLib.instructions.makeInstructions { ... }` (preserve the existing call)
- [x] 3.5 Migrate subagents: replace the `home.file.".claude/agent/*.md"` block with `programs.claude-code.agents` attrs (use `llmLib.instructions.formatSubagentAsMarkdown` output as inline strings)
- [x] 3.6 Migrate hook: replace `xdg.dataFile."claude/hooks/append_agentsmd_context.sh"` with `programs.claude-code.hooks.append_agentsmd_context = <script content>`
- [x] 3.7 Set `programs.claude-code.skillsDir = ./skills` (pointing to the existing skills directory)
- [x] 3.8 Remove all old `xdg.configFile`, `xdg.dataFile`, and `home.file` entries that are now managed by the native module

## 4. Migrate config/codex.nix to programs.codex

- [x] 4.1 Add `programs.codex.enable = true` and `programs.codex.package = pkgs.codex`
- [x] 4.2 Set `programs.codex.enableMcpIntegration = true`
- [x] 4.3 Set `programs.codex.custom-instructions = llmLib.instructions.makeInstructions { ... }` (same call as current AGENTS.md generation)
- [x] 4.4 Remove old `xdg.configFile."codex/config.toml"` and `xdg.configFile."codex/AGENTS.md"` entries

## 5. Verify

- [x] 5.1 Run `nh darwin switch` and confirm no build errors
- [x] 5.2 Confirm `~/.claude/settings.json` exists and contains expected content
- [x] 5.3 Confirm `~/.claude/CLAUDE.md` exists with instructions content
- [x] 5.4 Confirm `~/.claude/agents/oracle.md` and `~/.claude/agents/librarian.md` exist (plural path)
- [x] 5.5 Confirm `~/.claude/agent/` (singular) does NOT exist
- [x] 5.6 Confirm `~/.claude/hooks/append_agentsmd_context` is present and executable
- [x] 5.7 Confirm `~/.claude/skills/shell-script-authoring/SKILL.md` exists
- [x] 5.8 Confirm codex config file exists at the version-appropriate path and contains MCP server entries
- [x] 5.9 Confirm codex AGENTS.md exists with instructions content
- [x] 5.10 Confirm gemini/goose/amp/etc. configs are unchanged (spot-check one)
