{
  config,
  lib,
  pkgs,
  ...
}:
{
  sysinit.llm.mcp.additionalServers = {
    ast-grep = {
      command = "${pkgs.ast-grep-mcp}/bin/ast-grep-server";
      description = "AST-based structural code search and analysis";
    };

    calldiff = {
      command = "${lib.getExe pkgs.calldiff}";
      args = [ "--mcp" ];
      description = "Call graphs: diff them across git trees, walk one, or find every path to a symbol";
    };

    playwright = {
      command = "${lib.getExe pkgs.playwright-mcp}";
      args = [
        "--isolated"
        "--headless"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };

    basic-memory = {
      command = "${pkgs.basic-memory}/bin/basic-memory";
      args = [ "mcp" ];
      description = "Shared cross-harness memory — Markdown note store readable by all agents";
    };

    orc = {
      command = "${lib.getExe pkgs.orc-cli}";
      args = [ "mcp" ];
      env.ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
      description = "Optional local agent orchestration, with tools only inside an active Orc workspace";
    };
  };

}
