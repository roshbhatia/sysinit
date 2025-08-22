{ config, pkgs, ... }:
{
  launchd.user.agents.wezterm-mux-server = {
    program = "${pkgs.wezterm}/bin/wezterm";
    programArguments = [
      "mux-server"
      "--daemonize"
    ];
    runAtLoad = true;
    standardOutPath = "/tmp/wezterm-mux-server.log";
    standardErrorPath = "/tmp/wezterm-mux-server.err";
  };

}
