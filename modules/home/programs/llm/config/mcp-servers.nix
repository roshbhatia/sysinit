{ ... }:
{
  # incident.io is intentionally absent: the company `laurel-eng` Claude Code
  # plugin already ships an `incidentio` MCP server, so declaring our own here
  # would double-connect. Let the auto-updating plugin own it.
  sysinit.llm.mcp.additionalServers = {
    ast-grep = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/ast-grep/ast-grep-mcp"
        "ast-grep-server"
      ];
      description = "AST-based structural code search and analysis";
    };

    playwright = {
      command = "npx";
      args = [
        "-y"
        "@playwright/mcp@latest"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };
  };
}
