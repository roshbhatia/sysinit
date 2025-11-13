{
  lib,
  values,
  pkgs,
  utils,
  ...
}:

let
  inherit (utils.themes) getThemePalette validateThemeConfig;

  validatedTheme = validateThemeConfig values.theme;
  palette = getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  semanticColors = utils.themes.utils.createSemanticMapping palette;
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
