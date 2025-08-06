{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;
  activeColorRaw = colors.semantic.error (throw "Missing error color in theme palette");
  inactiveColorRaw = colors.accent.primary or (throw "Missing primary accent color in theme palette");
  activeColor = lib.toLower (lib.removePrefix "#" activeColorRaw);
  inactiveColor = lib.toLower (lib.removePrefix "#" inactiveColorRaw);
in
{
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;

    style = "round";
    width = 3.0;
    hidpi = true;
    active_color = "0xff${activeColor}";
    inactive_color = "0xff${inactiveColor}";
  };
}

