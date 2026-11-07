{ pkgs, home }:
let
  module = import ../modules/nixos/home/launcher.nix {
    inherit (pkgs) lib;
    config = home;
    pkgs = pkgs // {
      sway = pkgs.hello;
    };
  };
  menu = name: pkgs.writeText "${name}.lua" module.xdg.configFile."elephant/menus/${name}.lua".text;
in
pkgs.runCommand "nixos-launcher-menus" { nativeBuildInputs = [ pkgs.lua5_4 ]; } ''
  lua ${./nixos-launcher.lua} ${menu "sessions"} ${menu "panes"} ${menu "tabs"} ${menu "windows"}
  touch "$out"
''
