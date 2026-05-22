## Context

The `modules/home/programs/llm/` directory manages configuration for 9+ AI/LLM tools. Two of those — Claude Code CLI and Codex CLI — now have native Home Manager modules (`programs.claude-code`, `programs.codex`) that cover nearly all of the functionality currently hand-wired via `xdg.configFile` and `home.file`.

The current approach:
- `config/claude.nix`: writes `claude_desktop_config.json`, `CLAUDE.md`, agent markdown files, and hook scripts via raw `xdg.configFile` / `home.file` / `xdg.dataFile` entries
- `config/codex.nix`: writes `config.toml` and `AGENTS.md` via `xdg.configFile`
- Both consume MCP server definitions from `mcp.nix`, formatted by tool-specific functions in `lib/mcp.nix`

Home Manager (master) provides:
- `programs.claude-code`: manages settings.json, CLAUDE.md, agents, commands, hooks, skills, rules, output styles, plugins, LSP, MCP servers
- `programs.codex`: manages config.toml/yaml (version-adaptive), AGENTS.md, skills, MCP integration via `programs.mcp`
- `programs.mcp`: shared MCP server registry; `enableMcpIntegration` in claude-code and codex reads from it automatically

## Goals / Non-Goals

**Goals:**
- Replace hand-wired `xdg.configFile` entries in `config/claude.nix` with `programs.claude-code` options
- Replace hand-wired `xdg.configFile` entries in `config/codex.nix` with `programs.codex` options
- Introduce `programs.mcp.servers` as the shared MCP source for these two tools
- Preserve all existing behavior: agents, skills, hooks, instructions, MCP server definitions
- Keep `lib/mcp.nix` formatters intact for the 7 remaining tools that don't have native HM modules

**Non-Goals:**
- Migrating gemini, amp, cursor, goose, crush, opencode, pi, or copilot-cli
- Changing the content of instructions, agents, skills, or MCP server definitions
- Adding new Claude Code features (commands, rules, plugins, LSP) — those are follow-on
- Adopting `programs.mcp` for non-native tools (goose, gemini, etc.)

## Decisions

### 1. `programs.mcp` as the shared MCP source for claude-code + codex only

The MCP server definitions currently live in `mcp.nix` and are formatted per-tool via `lib/mcp.nix`. After migration, claude-code and codex will read from `programs.mcp.servers` via `enableMcpIntegration = true`. The remaining 7 tools still consume the formatted output from `lib/mcp.nix`.

**Alternatives considered:**
- Keep all MCP in `mcp.nix` and pass to native modules via `programs.claude-code.mcpServers` directly — possible but loses the `programs.mcp` integration and the native module's `disabled`/`headers` field handling
- Move all tools to `programs.mcp` — not viable since most tools have no native `enableMcpIntegration`

**Decision:** `programs.mcp.servers` becomes the canonical source for claude-code and codex; `lib/mcp.nix` formatters remain for the rest.

### 2. Keep `makeInstructions` — pass output to native memory/custom-instructions

The dynamic instruction generator (`makeInstructions` in `lib/instructions.nix`) produces CLAUDE.md / AGENTS.md content from skill metadata. Rather than abandoning this, its string output is passed directly to:
- `programs.claude-code.memory.text` (for Claude Code)
- `programs.codex.custom-instructions` (for Codex)

**Alternatives considered:**
- Convert to static markdown files and use `memory.source` / a path — loses the dynamic skill list
- Restructure instructions into native `rules` files — bigger change, deferred

**Decision:** Preserve `makeInstructions`, pipe its output into native options.

### 3. Subagents via `programs.claude-code.agents`

Current subagents are installed via `home.file` to `.claude/agent/*.md` (singular). The native module writes to `.claude/agents/` (plural). Migrating means the old path is gone and Claude Code reads agents from the new path.

**Decision:** Migrate. The native module manages this correctly and the directory rename is a one-time break.

### 4. Hook script via `programs.claude-code.hooks`

The `append_agentsmd_context.sh` hook is currently in `xdg.dataFile`. The native `hooks` option writes to `.claude/hooks/` and auto-makes files executable. The hook content is unchanged.

**Decision:** Move hook content inline to `programs.claude-code.hooks`.

### 5. Skills via `programs.claude-code.skillsDir`

The existing `skills/` directory (with `shell-scripting.nix` etc.) can be pointed to directly via `skillsDir`. This avoids reformatting skill content.

**Decision:** Use `skillsDir` pointing to the existing skills directory.

## Risks / Trade-offs

- **`.claude/agent/` → `.claude/agents/` rename** → Any Claude Code sessions mid-flight won't see agents until after rebuild. Mitigation: rebuild is atomic; no persistent sessions to worry about.
- **`programs.mcp` availability** → Requires home-manager master (or recent release with these modules). The flake already pins to HM master. Mitigation: verify modules exist before applying.
- **`force = true` removed** → Native modules don't force-overwrite. If a user-edited file exists, HM will error on conflict. Mitigation: clean `.claude/` managed files before first apply, or use `home.file.<n>.force` override if needed.
- **Codex version detection** → Native module adapts paths by codex version (`isAgentsSkillsSupported`). If `pkgs.codex` is pre-0.94.0, skills land in `.codex/skills` not `.agents/skills`. Mitigation: check `pkgs.codex` version in nixpkgs pin before migration.

## Migration Plan

1. Verify `programs.claude-code` and `programs.codex` modules exist in the pinned HM version
2. Rewrite `config/claude.nix` using native module options (settings, memory, agents, hooks, skillsDir)
3. Rewrite `config/codex.nix` using native module options (settings, custom-instructions, enableMcpIntegration)
4. Add `programs.mcp.servers` block with current MCP server definitions
5. Enable `enableMcpIntegration = true` in both native modules
6. Remove old `xdg.configFile` / `home.file` / `xdg.dataFile` entries for claude and codex
7. Run `darwin-rebuild switch` and verify:
   - `.claude/settings.json` present and correct
   - `.claude/CLAUDE.md` present with expected content
   - `.claude/agents/*.md` present (plural path)
   - `.claude/hooks/append_agentsmd_context` present and executable
   - `.claude/skills/` populated
   - `~/.codex/config.toml` or `~/.config/codex/config.toml` present with MCP servers
   - `~/.codex/AGENTS.md` present with expected content
8. Rollback: `git revert` and rebuild — all changes are in Nix, no persistent state outside the store

## Open Questions

- Does the pinned `pkgs.codex` version support `0.94.0+` (`.agents/skills` path)? Need to check before migration.
- Should `mcp.nix` be cleaned up or removed after migration, or kept as the source for the remaining 7 tools? (Current plan: keep it, it still feeds gemini/goose/amp/etc.)
