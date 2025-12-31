# LLM Configurations

Centralized configuration for AI/LLM development tools.

## Supported Tools

- **Claude** - Anthropic Claude Desktop
- **OpenCode** - OpenCode AI coding assistant
- **Crush** - Crush AI coding assistant
- **Cursor** - Cursor AI code editor
- **Goose** - Goose AI CLI
- **Amp** - Sourcegraph Amp
- **GitHub Copilot** - GitHub Copilot CLI (both .copilot and github-copilot)

## Architecture

### Shared Utilities

All LLM clients use shared formatters from \`modules/shared/lib/llm\`:

- **MCP formatters** - Transform MCP server config for each client's schema
- **Permission formatters** - Format shell permission lists for each client
- **LSP formatters** - Format LSP server configs

### Configuration Pattern

Each LLM config uses standard home-manager patterns:

\`\`\`nix
{
  xdg.configFile = {
    "app/config.json".text = builtins.toJSON { ... };
  };
  xdg.dataFile = {
    "app/script.sh" = {
      text = "...";
      executable = true;
    };
  };
}
\`\`\`

No activation scripts, no file comparison logic - clean and idempotent.

### Shared Resources

- \`shared/mcp-servers.nix\` - MCP server definitions
- \`shared/lsp.nix\` - LSP server configuration
- \`shared/directives.nix\` - AGENTS.md content
- \`shared/skills/\` - OpenCode skills (symlinked)
- \`shared/subagents/\` - OpenCode subagents
