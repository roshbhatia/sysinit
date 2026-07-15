{ lib, pkgs, ... }:
let
  basicMemoryMcp = pkgs.writeShellScript "basic-memory-mcp" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.cargo
        pkgs.rustc
        pkgs.uv
      ]
    }:$PATH"
    export UV_PYTHON="${pkgs.python313}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never

    exec ${pkgs.uv}/bin/uvx basic-memory mcp "$@"
  '';
in
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

    playwright = {
      command = "npx";
      args = [
        "-y"
        "@playwright/mcp@latest"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };

    # Shared Markdown-backed memory store accessible by every harness.
    # Backing directory defaults to ~/Documents/basic-memory/; all agents
    # read and write the same files, giving cross-harness persistent context.
    basic-memory = {
      command = "${basicMemoryMcp}";
      description = "Shared cross-harness memory — Markdown note store readable by all agents";
    };
  };
}
