{
  lib,
  values,
  config,
  ...
}:

let
  bordersEnabled = values.darwin.borders.enable;

  colors = config.lib.stylix.colors;
  hexToJanky = hex: "0xff${hex}";
in
{
  services.jankyborders = lib.mkIf bordersEnabled {
    enable = true;
    width = 6.0;
    active_color = lib.mkForce (hexToJanky colors.base0D);
    inactive_color = lib.mkForce (hexToJanky colors.base02);
  };
}
