{
  lib,
  utils,
  ...
}:

with lib;

let
  themeNames = import ./theme-names.nix { inherit lib; };
in

{
  createNeovimConfig =
    themeData: config: overrides:
    let
      pluginInfo = themeNames.getNeovimConfig themeData.meta.id config.variant;

      baseConfig = {
        inherit (pluginInfo)
          plugin
          name
          setup
          colorscheme
          ;

        config = {
          transparent = true;
          terminal_colors = true;
          styles = {
            comments = {
              italic = true;
            };
            keywords = {
              bold = true;
            };
            functions = {
              bold = true;
            };
            strings = {
              italic = true;
            };
            variables = { };
            numbers = {
              bold = true;
            };
            booleans = {
              bold = true;
              italic = true;
            };
            properties = {
              italic = true;
            };
            types = {
              bold = true;
            };
            operators = {
              bold = true;
            };
          };
        };
      };
    in
    utils.mergeThemeConfigs baseConfig overrides;

  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      pluginInfo = themeNames.getNeovimConfig themeData.meta.id config.variant;
    in
    {
      inherit (config) colorscheme variant;
      appearance = if hasAttr "appearance" config then config.appearance else null;
      font = if hasAttr "font" config then config.font else null;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit (pluginInfo) plugin name setup;
      theme_colorscheme = pluginInfo.colorscheme;
      inherit palette;
      semanticColors = semanticColors // {
        extended = palette;
      };
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
