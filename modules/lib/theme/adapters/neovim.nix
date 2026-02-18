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
      pluginInfo = themeNames.getNeovimMetadata themeData.meta.id config.variant;

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
    in
    {
      inherit (config) colorscheme variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors;
    };
}
