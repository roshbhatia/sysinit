{ lib, ... }:

with lib;

let
  stylix = import ../core/stylix.nix { inherit lib; };
in

{
  createBatConfig =
    theme: themeConfig: overrides:
    let
      stylixTargets = stylix.enableStylixTargets ["bat"];
    in
    stylixTargets;

  # Generate JSON config for external consumption
  generateBatJSON =
    theme: themeConfig:
    let
      palette = theme.palettes.${themeConfig.variant};
      semanticColors = theme.semanticMapping palette;
    in
    {
      colorscheme = "${themeConfig.colorscheme}-${themeConfig.variant}";
      variant = themeConfig.variant;
      palette = palette;
      semanticColors = semanticColors;
      appTheme = getAppTheme "bat" themeConfig.colorscheme themeConfig.variant;
    };
}
