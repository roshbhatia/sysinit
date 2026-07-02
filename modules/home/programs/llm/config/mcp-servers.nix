_: {
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

    aws-knowledge-mcp-server = {
      type = "http";
      url = "https://knowledge-mcp.global.api.aws";
      description = "AWS documentation and service knowledge";
    };

    # Codex CLI running in MCP server mode (v0.117+). Lets Claude Code and
    # other MCP clients delegate tasks to Codex as a sub-agent tool call.
    # Codex will also see this entry in its own MCP config; that's intentional —
    # it enables Codex-spawns-Codex parallelism.
    codex-mcp = {
      command = "codex";
      args = [ "mcp-server" ];
      description = "Codex CLI as MCP server — delegate coding tasks to Codex from any agent";
    };

    # Shared Markdown-backed memory store accessible by every harness.
    # Backing directory defaults to ~/Documents/basic-memory/; all agents
    # read and write the same files, giving cross-harness persistent context.
    basic-memory = {
      command = "uvx";
      args = [ "basic-memory" "mcp" ];
      description = "Shared cross-harness memory — Markdown note store readable by all agents";
    };
  };
}
