{
  lib,
  config,
  ...
}:

let
  colors = config.lib.stylix.colors;
  hexToJanky = hex: "0xff${hex}";
in
{
  services.jankyborders = {
    enable = true;
    width = 6.0;
    active_color = lib.mkForce (hexToJanky colors.base0D);
    inactive_color = lib.mkForce (hexToJanky colors.base02);
  };
}
