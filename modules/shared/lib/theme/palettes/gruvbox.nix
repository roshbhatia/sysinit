{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Gruvbox";
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
    author = "morhetz";
    homepage = "https://github.com/morhetz/gruvbox";
  };

  palettes = {
    dark = utils.validatePalette rec {
      bg0_h = "#1d2021";
      bg0 = "#282828";
      bg0_s = "#32302f";
      bg1 = "#3c3836";
      bg2 = "#504945";
      bg3 = "#665c54";
      bg4 = "#7c6f64";

      fg0 = "#fbf1c7";
      fg1 = "#ebdbb2";
      fg2 = "#d5c4a1";
      fg3 = "#bdae93";
      fg4 = "#a89984";

      gray = "#928374";

      red = "#fb4934";
      green = "#b8bb26";
      yellow = "#fabd2f";
      blue = "#83a598";
      purple = "#d3869b";
      aqua = "#8ec07c";
      orange = "#fe8019";

      neutral_red = "#cc241d";
      neutral_green = "#98971a";
      neutral_yellow = "#d79921";
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
      fg = fg1;
      fg_alt = fg2;
      comment = gray;
      cyan = aqua;
      teal = aqua;
      accent = blue;
      accent_dim = bg1;
    };

    light = utils.validatePalette rec {
      bg0_h = "#f9f5d7";
      bg0 = "#fbf1c7";
      bg0_s = "#f2e5bc";
      bg1 = "#ebdbb2";
      bg2 = "#d5c4a1";
      bg3 = "#bdae93";
      bg4 = "#a89984";

      fg0 = "#282828";
      fg1 = "#3c3836";
      fg2 = "#504945";
      fg3 = "#665c54";
      fg4 = "#7c6f64";

      gray = "#928374";

      red = "#cc241d";
      green = "#98971a";
      yellow = "#d79921";
      blue = "#458588";
      purple = "#b16286";
      aqua = "#689d6a";
      orange = "#d65d0e";

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
      fg = fg1;
      fg_alt = fg2;
      comment = gray;
      cyan = aqua;
      teal = aqua;
      accent = blue;
      accent_dim = bg1;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
