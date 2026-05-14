{ config, ... }:
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
      # Absolute path: pipx installs to ~/.local/bin, which is not always
      # on PATH for MCP subprocesses spawned by GUI-launched harnesses.
      command = "${config.home.homeDirectory}/.local/bin/ccc";
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
  };
}
