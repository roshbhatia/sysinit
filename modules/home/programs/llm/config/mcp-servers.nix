{
  lib,
  pkgs,
  values,
  ...
}:
{
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

    cocoindex = {
      command = "${pkgs.cocoindex-code}/bin/ccc";
      args = [ "mcp" ];
      description = "Semantic code search over a project-local index (cocoindex-code, local embeddings)";
    };

    playwright = {
      command = "npx";
      args = [
        "-y"
        "@playwright/mcp@latest"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };
  }
  // lib.optionalAttrs (values.isWork or false) {
    incident-io = {
      type = "http";
      url = "https://mcp.incident.io/mcp";
      description = "incident.io remote MCP (work) — incidents, follow-ups, post-mortems";
    };
  };
}
