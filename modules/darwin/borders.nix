{
  lib,
  config,
  ...
}:

let
  # The palette, read through one accessor rather than reached for directly.
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
    # The launcher is a borderless panel that draws its own rounded edge, and a border
    # traced around its square window frame sits outside that edge rather than on it.
    blacklist = [ "Hammerspoon" ];
  };
}
