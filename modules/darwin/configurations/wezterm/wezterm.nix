{ config, pkgs, ... }:
{
  launchd.user.agents.wezterm-mux-server = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.wezterm}/bin/wezterm" "mux-server" "--daemonize" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/wezterm-mux-server.log";
      StandardErrorPath = "/tmp/wezterm-mux-server.err";
    };
  };
}
