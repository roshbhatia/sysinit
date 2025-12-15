{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Solarized";
    id = "solarized";
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
    author = "Ethan Schoonover";
    homepage = "https://ethanschoonover.com/solarized/";
  };

  palettes = {
    dark = utils.validatePalette (rec {
      base03 = "#002b36";
      base02 = "#073642";
      base01 = "#586e75";
      base00 = "#657b83";
      base0 = "#839496";
      base1 = "#93a1a1";
      base2 = "#eee8d5";
      base3 = "#fdf6e3";

      yellow = "#b58900";
      orange = "#cb4b16";
      red = "#dc322f";
      magenta = "#d33682";
      violet = "#6c71c4";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";

      base = base03;
      bg = base03;
      bg_alt = base02;
      surface = base02;
      surface_alt = base01;
      text = base0;
      fg = base0;
      fg_alt = base00;
      comment = base01;
      purple = violet;
      teal = cyan;
      accent = blue;
      accent_dim = base02;
    });

    light = utils.validatePalette (rec {
      base03 = "#002b36";
      base02 = "#073642";
      base01 = "#586e75";
      base00 = "#657b83";
      base0 = "#839496";
      base1 = "#93a1a1";
      base2 = "#eee8d5";
      base3 = "#fdf6e3";

      yellow = "#b58900";
      orange = "#cb4b16";
      red = "#dc322f";
      magenta = "#d33682";
      violet = "#6c71c4";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";

      base = base3;
      bg = base3;
      bg_alt = base2;
      surface = base2;
      surface_alt = base1;
      text = base00;
      fg = base00;
      fg_alt = base0;
      comment = base1;
      purple = violet;
      teal = cyan;
      accent = blue;
      accent_dim = base2;
    });
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
