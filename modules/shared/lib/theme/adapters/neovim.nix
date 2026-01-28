{
  lib,
  utils,
  ...
}:

with lib;

{
  # Pixel.nvim adapter - uses terminal ANSI colors, so no theme-specific config needed
  createNeovimConfig =
    themeData: config: overrides:
    let
      baseConfig = {
        # Pixel.nvim is configured directly in the Neovim plugin file
        # and automatically uses terminal ANSI colors
        colorscheme = "pixel";
        plugin = "bjarneo/pixel.nvim";
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
      # Always use pixel as the colorscheme since it adapts to terminal colors
      colorscheme = "pixel";
      inherit (config) variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      inherit semanticColors;
    };
}
