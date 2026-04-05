{ ... }:
{
  sysinit.llm.mcp.additionalServers = {
    ast-grep = {
      command = "npx";
      args = [
        "-y"
        "@ast-grep/mcp"
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
