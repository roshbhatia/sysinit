{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;
  palette = theme.palettes.${validatedTheme.variant};
  semanticColors = theme.semanticMapping palette;

  activeColorRaw = semanticColors.semantic.error or (throw "Missing error color in theme palette");
  inactiveColorRaw =
    semanticColors.accent.primary or (throw "Missing primary accent color in theme palette");
  activeColor = lib.toLower (lib.removePrefix "#" activeColorRaw);
  inactiveColor = lib.toLower (lib.removePrefix "#" inactiveColorRaw);
  bordersEnabled = values.darwin.borders.enable or true;
in
lib.mkIf bordersEnabled {
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;

    style = "round";
    width = 4.0;
    hidpi = true;
    active_color = "0xff${activeColor}";
    inactive_color = "0xff${inactiveColor}";
  };
}
