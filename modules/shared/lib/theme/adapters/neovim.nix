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
    in
    {
      inherit (config) colorscheme variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors;
    };

  generateThemeLuaMap =
    allThemes:
    let
      buildThemeEntry =
        themeId: themeData:
        let
          inherit (themeData.meta) variants;
          buildVariant =
            variant:
            let
              pluginInfo = themeNames.getNeovimConfig themeId variant;
            in
            ''
              ${variant} = {
                plugin = "${pluginInfo.plugin}",
                name = "${pluginInfo.name}",
                setup = "${pluginInfo.setup}",
                colorscheme = "${pluginInfo.colorscheme}",
              }'';
        in
        ''
            ${themeId} = {
          ${concatStringsSep ",\n" (map buildVariant variants)}
            }'';
    in
    ''
          local THEME_CONFIG_MAP = {
      ${concatStringsSep ",\n" (mapAttrsToList buildThemeEntry allThemes)}
          }

          return THEME_CONFIG_MAP
    '';
}
