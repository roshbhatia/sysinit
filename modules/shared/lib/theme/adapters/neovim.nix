{
  lib,
  utils,
  ...
}:

let
  themeNames = import ./theme-names.nix { inherit lib; };
in

{
  createNeovimConfig =
    themeData: config: overrides:
    let
      pluginInfo = themeNames.getNeovimMetadata themeData.id config.variant;

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

  # Legacy function - no longer used since migration to stylix
  generateNeovimJSON = _themeData: config: {
    inherit (config) colorscheme variant;
    transparency = config.transparency or (throw "Missing transparency configuration");
  };
}
