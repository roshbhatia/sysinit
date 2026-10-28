{
  config,
  lib,
  pkgs,
  ...
}:
{
  sysinit.llm.mcp.suppressedServers = [ "basic-memory" ];

  sysinit.llm.mcp.additionalServers = {
    atuin = {
      command = lib.getExe config.programs.atuin.package;
      args = [ "mcp" ];
      env.ATUIN_CONFIG_DIR = "${config.xdg.configHome}/atuin";
      description = "Search local shell history and captured agent Threads";
    };

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

  };

}
