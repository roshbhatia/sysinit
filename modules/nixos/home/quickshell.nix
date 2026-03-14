# Quickshell bar integration for niri
{
  pkgs,
  inputs,
  ...
}:

let
  quickshellPkg = inputs.quickshell.packages.${pkgs.system}.default;
  niriPkg = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;

  quickshellWrapped = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [
      quickshellPkg
      niriPkg
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
}
