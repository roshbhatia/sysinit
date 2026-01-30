{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Flexoki";
    id = "flexoki";
    variants = [ "light" ];
    supports = [ "light" ];
    appearanceMapping = {
      light = "light";
    };
    author = "Steph Ango (kepano)";
    homepage = "https://github.com/kepano/flexoki";
  };

  palettes = {
    light = utils.validatePalette rec {
      # Flexoki base colors (backgrounds)
      paper = "#FFFCF0";
      base_50 = "#F2F0E5";
      base_100 = "#E6E4D9";
      base_150 = "#DAD8CE";
      base_200 = "#CECDC3";
      base_300 = "#B7B5AC";
      base_400 = "#9F9D96";
      base_500 = "#878580";
      base_600 = "#6F6E69";
      base_700 = "#575653";
      base_800 = "#403E3C";

      # Flexoki accent colors (600 variants for light mode)
      red_600 = "#AF3029";
      orange_600 = "#BC5215";
      yellow_600 = "#AD8301";
      green_600 = "#66800B";
      cyan_600 = "#24837B";
      blue_600 = "#205EA6";
      purple_600 = "#5E409D";
      magenta_600 = "#A02F6F";

      # Required theme system mappings
      base = paper;
      bg = paper;
      bg_alt = base_50;
      fg = base_800;
      fg_alt = base_700;
      surface = base_100;
      surface_alt = base_150;
      overlay = base_200;

      text = base_800;
      subtext1 = base_700;
      subtext0 = base_600;
      comment = base_500;
      subtle = base_400;
      teal = cyan_600;

      # Required color mappings
      red = red_600;
      orange = orange_600;
      yellow = yellow_600;
      green = green_600;
      cyan = cyan_600;
      blue = blue_600;
      purple = purple_600;
      magenta = magenta_600;

      # Accent system
      accent = blue_600;
      accent_secondary = cyan_600;
      accent_tertiary = purple_600;
      accent_dim = base_150;

      # UI highlights
      highlight_low = base_50;
      highlight_med = base_100;
      highlight_high = base_150;

      # Base16 colors for stylix
      base00 = paper;
      base01 = base_50;
      base02 = base_100;
      base03 = base_500;
      base04 = base_600;
      base05 = base_800;
      base06 = base_700;
      base07 = base_150;
      base08 = red_600;
      base09 = orange_600;
      base0A = yellow_600;
      base0B = green_600;
      base0C = cyan_600;
      base0D = blue_600;
      base0E = purple_600;
      base0F = magenta_600;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
