{
  lib,
  config,
  ...
}:

let
  themeLib = import ../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  colors = themeColors;
  hexToJanky = hex: "0xff${hex}";
in
{
  services.jankyborders = {
    enable = true;
    width = 6.0;
    active_color = lib.mkForce (hexToJanky colors.base0D);
    inactive_color = lib.mkForce (hexToJanky colors.base02);
    blacklist = [ "Hammerspoon" ];
  };
}
