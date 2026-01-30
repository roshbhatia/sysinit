{
  pkgs,
  lib,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme.nix { inherit lib; };
  themeConfig = values.theme;

  # Get the palette for current colorscheme + variant
  palette = themes.getThemePalette themeConfig.colorscheme themeConfig.variant;

  # Helper to remove # prefix from color values
  stripHash = color: lib.removePrefix "#" color;

  # Base16 scheme as an attrset
  base16Scheme = {
    scheme = "${themeConfig.colorscheme}-${themeConfig.variant}";
    author = "sysinit";
    base00 = stripHash palette.base00;
    base01 = stripHash palette.base01;
    base02 = stripHash palette.base02;
    base03 = stripHash palette.base03;
    base04 = stripHash palette.base04;
    base05 = stripHash palette.base05;
    base06 = stripHash palette.base06;
    base07 = stripHash palette.base07;
    base08 = stripHash palette.base08;
    base09 = stripHash palette.base09;
    base0A = stripHash palette.base0A;
    base0B = stripHash palette.base0B;
    base0C = stripHash palette.base0C;
    base0D = stripHash palette.base0D;
    base0E = stripHash palette.base0E;
    base0F = stripHash palette.base0F;
  };

  # Generate YAML and write to file
  schemeYaml = lib.generators.toYAML { } base16Scheme;
  schemeFile = pkgs.writeText "base16-scheme.yaml" schemeYaml;
in
{
  stylix = {
    enable = true;

    polarity = themeConfig.appearance;
    base16Scheme = schemeFile;

    fonts = {
      monospace.name = themeConfig.font.monospace;
      sansSerif.name = themeConfig.font.monospace;
      serif.name = themeConfig.font.monospace;
      sizes = {
        terminal = 11;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };

    opacity = {
      terminal = themeConfig.transparency.opacity;
      applications = themeConfig.transparency.opacity;
      popups = themeConfig.transparency.opacity;
    };
  };
}
