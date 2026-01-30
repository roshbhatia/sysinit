{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Gruvbox Material";
    id = "gruvbox";
    variants = [
      "dark"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "dark";
    };
    author = "sainnhe";
    homepage = "https://github.com/sainnhe/gruvbox-material";
  };

  palettes = {
    dark = utils.validatePalette rec {
      # Gruvbox Material Dark (medium contrast)
      bg0_h = "#202020";
      bg0 = "#282828";
      bg0_s = "#32302f";
      bg1 = "#3a3a3a";
      bg2 = "#45403d";
      bg3 = "#524f45";
      bg4 = "#5a5047";

      fg0 = "#fdf4c1";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      gray = "#928374";

      # Material-inspired colors (warmer, more muted)
      red = "#ea6962";
      green = "#a9b665";
      yellow = "#d8b356";
      blue = "#7daea3";
      purple = "#d3869b";
      aqua = "#89b482";
      orange = "#e78a4e";

      neutral_red = "#c14a4a";
      neutral_green = "#8b9d2f";
      neutral_yellow = "#b8860b";
      neutral_blue = "#458588";
      neutral_purple = "#b16286";
      neutral_aqua = "#689d6a";

      dark_red = "#421e1e";
      dark_green = "#2d3319";
      dark_yellow = "#4e3e1e";
      dark_blue = "#2d4650";
      dark_purple = "#4a3650";
      dark_aqua = "#36473a";

      base = bg0;
      bg = bg0;
      bg_alt = bg0_h;
      surface = bg1;
      surface_alt = bg2;
      text = fg1;
      subtext1 = fg2;
      subtext0 = fg3;
      fg = fg1;
      fg_alt = fg2;
      comment = gray;
      cyan = aqua;
      teal = aqua;
      accent = blue;
      accent_dim = bg1;

      # Base16 colors for stylix
      base00 = bg0;
      base01 = bg0_h;
      base02 = bg1;
      base03 = gray;
      base04 = fg3;
      base05 = fg1;
      base06 = fg2;
      base07 = fg0;
      base08 = red;
      base09 = orange;
      base0A = yellow;
      base0B = green;
      base0C = aqua;
      base0D = blue;
      base0E = purple;
      base0F = orange;
    };

    light = utils.validatePalette rec {
      # Gruvbox Material Light (hard contrast)
      bg0_h = "#f2f0e5";
      bg0 = "#faf6f1";
      bg0_s = "#ede6d3";
      bg1 = "#eae2b7";
      bg2 = "#d8cdb4";
      bg3 = "#c9bfa6";
      bg4 = "#bab090";

      fg0 = "#3d3d3d";
      fg1 = "#654735";
      fg2 = "#654735";
      fg3 = "#8d7c6e";
      fg4 = "#9d8a7c";

      gray = "#8d7c6e";

      # Material-inspired colors for light (warm, slightly desaturated)
      red = "#c14a4a";
      green = "#8b9d2f";
      yellow = "#b8860b";
      blue = "#2b7a78";
      purple = "#a85e9e";
      aqua = "#6b9c7a";
      orange = "#d8860b";

      bright_red = "#9d0006";
      bright_green = "#79740e";
      bright_yellow = "#b57614";
      bright_blue = "#076678";
      bright_purple = "#8f3f71";
      bright_aqua = "#427b58";
      bright_orange = "#af3a03";

      base = bg0;
      bg = bg0;
      bg_alt = bg0_h;
      surface = bg1;
      surface_alt = bg2;
      text = fg1;
      subtext1 = fg2;
      subtext0 = fg3;
      fg = fg1;
      fg_alt = fg2;
      comment = gray;
      cyan = aqua;
      teal = aqua;
      accent = blue;
      accent_dim = bg1;

      # Base16 colors for stylix
      base00 = bg0;
      base01 = bg0_h;
      base02 = bg1;
      base03 = gray;
      base04 = fg3;
      base05 = fg1;
      base06 = fg2;
      base07 = fg0;
      base08 = red;
      base09 = orange;
      base0A = yellow;
      base0B = green;
      base0C = aqua;
      base0D = blue;
      base0E = purple;
      base0F = orange;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
