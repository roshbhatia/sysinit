{
  lib,
  utils,
  ...
}:

let
  themeNames = import ./theme-names.nix { inherit lib; };
in

{
  createWeztermConfig =
    themeData: config: _overrides:
    let
      themeName = themeNames.getWeztermTheme themeData.meta.id config.variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
    in
    {
      color_scheme = themeName;
      macos_window_background_blur = transparency.blur or 0;
      window_background_opacity = transparency.opacity or 1.0;
    };

  generateWeztermJSON =
    themeData: config:
    let
      themeName = themeNames.getWeztermTheme themeData.meta.id config.variant;
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      ansi = utils.generateAnsiMappings semanticColors;
    in
    {
      inherit themeName;
      transparency = config.transparency or (throw "Missing transparency configuration");
      font = config.font or { };
      inherit ansi palette semanticColors;
    };
}
