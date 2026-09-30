{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.cua-driver ];

  home.activation.registerCuaDriver = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "copyApps" "sysinitCodesign" ] ''
      run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ${lib.escapeShellArg "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/CuaDriver.app"}
    ''
  );

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

    cua =
      (
        if pkgs.stdenv.hostPlatform.isDarwin then
          {
            command = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/CuaDriver.app/Contents/MacOS/cua-driver";
            args = [ "mcp" ];
          }
        else
          {
            type = "http";
            url = "http://localhost:8000/mcp";
          }
      )
      // {
        description = "Native computer controls on this machine: screenshots, keyboard, mouse, and windows";
      };

    orc = {
      command = "${lib.getExe pkgs.orc-cli}";
      args = [ "mcp" ];
      env.ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
      description = "Optional local agent orchestration, with tools only inside an active Orc workspace";
    };
  };

  systemd.user.services.cua-computer-server = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Cua computer server, the host side of computer use";
      StartLimitBurst = 3;
      StartLimitIntervalSec = 300;
    };
    Service = {
      ExecStart = lib.getExe pkgs.cua-computer-server;
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
