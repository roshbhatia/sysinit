{ lib, ... }:

with lib;

let
  stylix = import ../core/stylix.nix { inherit lib; };
in

{
  createHelixConfig =
    theme: themeConfig: overrides:
    let
      stylixTargets = stylix.enableStylixTargets ["helix"];
    in
    stylixTargets;

  generateHelixJSON =
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
    };
}
