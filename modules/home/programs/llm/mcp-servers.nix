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

  # cua is not in nixpkgs and both halves need Python 3.12 or 3.13, so uv owns
  # the environment. Both versions are pinned: uvx keys its cache on the
  # requirement string, and cua-mcp-server resolves to 136 packages including
  # torch and transformers, so an unpinned string re-downloads gigabytes on any
  # upstream release.
  cuaMcpVersion = "0.1.16";
  cuaComputerServerVersion = "0.3.42";

  uvEnv = ''
    export PATH="${lib.makeBinPath [ pkgs.uv ]}:$PATH"
    export UV_PYTHON="${pkgs.python313}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never
  '';

  cuaMcp = pkgs.writeShellScript "cua-mcp-server" ''
    set -euo pipefail
    ${uvEnv}
    # The agent drives this machine, not a Lume VM. That needs the host computer
    # server on port 8000, which the service below keeps running.
    export CUA_USE_HOST_COMPUTER_SERVER=true

    exec ${pkgs.uv}/bin/uvx "cua-mcp-server==${cuaMcpVersion}" "$@"
  '';

  cuaComputerServer = pkgs.writeShellScript "cua-computer-server" ''
    set -euo pipefail
    ${uvEnv}

    # No [mcp] extra: 0.3.42 does not publish one, and cua-mcp-server reaches
    # this server over its HTTP and WebSocket API rather than over MCP.
    exec ${pkgs.uv}/bin/uv run --no-project \
      --with "cua-computer-server==${cuaComputerServerVersion}" \
      python -m computer_server "$@"
  '';

in
{
  home.packages = [ pkgs.orca ];

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
      command = "npx";
      args = [
        "-y"
        "@playwright/mcp@latest"
      ];
      description = "Browser automation and end-to-end testing via Playwright";
    };

    basic-memory = {
      command = "${basicMemoryMcp}";
      description = "Shared cross-harness memory — Markdown note store readable by all agents";
    };

    cua = {
      command = "${cuaMcp}";
      description = "Computer use on this machine: screenshot the screen and run a task against the desktop";
    };

    orca = {
      command = "${lib.getExe pkgs.orca}";
      args = [ "mcp" ];
      description = "Optional local agent orchestration, with tools only inside an active Orca workspace";
    };
  };

  # Both are declared on both hosts. home-manager gates each on its own `enable`,
  # which already defaults to the platform that owns it, so the one that does not
  # apply writes nothing.
  launchd.agents.cua-computer-server = {
    enable = true;
    config = {
      ProgramArguments = [ "${cuaComputerServer}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cua-computer-server.log";
      StandardErrorPath = "/tmp/cua-computer-server.error.log";
    };
  };

  systemd.user.services.cua-computer-server = {
    Unit.Description = "Cua computer server, the host side of computer use";
    Service = {
      ExecStart = "${cuaComputerServer}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
