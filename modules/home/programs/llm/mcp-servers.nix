{
  config,
  lib,
  pkgs,
  ...
}:
let
  basicMemoryMcp = pkgs.sysinit.writeShellScript "basic-memory-mcp" ''
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

  cuaComputerServerVersion = "0.3.42";

  uvEnv = ''
    export PATH="${lib.makeBinPath [ pkgs.uv ]}:$PATH"
    export UV_PYTHON="${pkgs.python313}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never
  '';

  cuaComputerServer = pkgs.sysinit.writeShellScript "cua-computer-server" ''
    set -euo pipefail
    ${uvEnv}
    export FASTMCP_STATELESS_HTTP=true

    exec ${lib.escapeShellArg "${config.sysinit.codesign.signedBinDir}/cua-uv"} run --no-project \
      --with "cua-computer-server==${cuaComputerServerVersion}" \
      --with "fastmcp==3.2.4" \
      python ${./runtime/cua-macos.py} "$@"
  '';

  cuaComputerServerCommand =
    if pkgs.stdenv.hostPlatform.isLinux then
      lib.getExe pkgs.cua-computer-server
    else
      "${cuaComputerServer}";

in
{
  sysinit.codesign.binaries = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    cua-uv = lib.getExe pkgs.uv;
  };

  sysinit.llm.mcp.additionalServers = {
    ast-grep = {
      command = "${lib.getExe' pkgs.uv "uvx"}";
      args = [
        "--from"
        "git+https://github.com/ast-grep/ast-grep-mcp"
        "ast-grep-server"
      ];
      description = "AST-based structural code search and analysis";
    };

    # Four meta tools, not three real ones: calldiff hides diff, reach and tree
    # behind search_tools and call_read_tool. That caps the context cost at four
    # slots, and costs three round trips where `Bash(calldiff:*)` costs one. It is
    # here for the harnesses that reach a tool more readily than a shell.
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
      command = "${basicMemoryMcp}";
      description = "Shared cross-harness memory — Markdown note store readable by all agents";
    };

    cua = {
      type = "http";
      url = "http://localhost:8000/mcp";
      description = "Native computer controls on this machine: screenshots, keyboard, mouse, and windows";
    };

    orc = {
      command = "${lib.getExe pkgs.orc-cli}";
      args = [ "mcp" ];
      env.ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
      description = "Optional local agent orchestration, with tools only inside an active Orc workspace";
    };
  };

  # Both are declared on both hosts. home-manager gates each on its own `enable`,
  # which already defaults to the platform that owns it, so the one that does not
  # apply writes nothing.
  launchd.agents.cua-computer-server = {
    enable = true;
    config = {
      ProgramArguments = [ cuaComputerServerCommand ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cua-computer-server.log";
      StandardErrorPath = "/tmp/cua-computer-server.error.log";
    };
  };

  systemd.user.services.cua-computer-server = {
    Unit = {
      Description = "Cua computer server, the host side of computer use";
      StartLimitBurst = 3;
      StartLimitIntervalSec = 300;
    };
    Service = {
      ExecStart = cuaComputerServerCommand;
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
