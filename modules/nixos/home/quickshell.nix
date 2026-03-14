# Quickshell bar integration for niri
{
  pkgs,
  inputs,
  ...
}:

let
  quickshellWrapped = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [
      inputs.quickshell.packages.${pkgs.system}.default
      pkgs.niri
      pkgs.wl-clipboard
    ];
  };
in
{
  home.packages = [ quickshellWrapped ];

  xdg.configFile."quickshell/default" = {
    source = ./quickshell;
    recursive = true;
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${quickshellWrapped}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
