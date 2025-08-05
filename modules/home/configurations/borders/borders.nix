{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;
  activeColor = lib.toLower (lib.removePrefix "#" (colors.accent.primary or "ffdc8a78"));
  inactiveColor = lib.toLower (lib.removePrefix "#" (colors.background.overlay or "ffbabbf1"));
in
{
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;

    style = "round";
    width = 3.0;
    hidpi = true;
    active_color = "0x${activeColor}";
    inactive_color = "0x${inactiveColor}";
  };
}
