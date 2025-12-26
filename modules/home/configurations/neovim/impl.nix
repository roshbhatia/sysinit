{
  lib,
  utils,
  ...
}:

let
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
in

{
  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      pluginInfo = themeNames.getNeovimConfig themeData.meta.id config.variant;
    in
    {
      inherit (config)
        colorscheme
        variant
        appearance
        font
        transparency
        ;
      inherit (pluginInfo) plugin name setup;
      inherit palette;
      semanticColors = semanticColors // {
        extended = palette;
      };
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
