{ lib, ... }:

with lib;

let
  stylix = import ../core/stylix.nix { inherit lib; };
in

{
  createK9sConfig =
    theme: themeConfig: overrides:
    let
      stylixTargets = stylix.enableStylixTargets ["k9s"];
    in
    stylixTargets;

  generateK9sJSON =
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
