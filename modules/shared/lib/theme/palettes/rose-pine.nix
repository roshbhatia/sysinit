{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Rosé Pine";
    id = "rose-pine";
    variants = [
      "dawn"
      "moon"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "dawn";
      dark = "moon";
    };
    author = "Rosé Pine";
    homepage = "https://github.com/rose-pine/rose-pine";
  };

  palettes = {
    dawn = utils.validatePalette rec {
      base = "#faf4ed";
      surface = "#fffaf3";
      overlay = "#f2e9e1";

      muted = "#9893a5";
      subtle = "#797593";
      text = "#575279";

      love = "#b4637a";
      gold = "#ea9d34";
      rose = "#d7827e";
      pine = "#286983";
      foam = "#56949f";
      iris = "#907aa9";
      leaf = "#6d8f89";

      highlight_low = "#f4ede8";
      highlight_med = "#dfdad9";
      highlight_high = "#cecacd";

      bg = base;
      bg_alt = surface;
      fg = text;
      fg_alt = subtle;
      comment = muted;
      red = love;
      green = leaf;
      yellow = gold;
      blue = pine;
      purple = iris;
      orange = rose;
      cyan = foam;
      teal = foam;
      accent = iris;
      accent_dim = overlay;
    };

    moon = utils.validatePalette rec {
      base = "#232136";
      surface = "#2a273f";
      overlay = "#393552";

      muted = "#6e6a86";
      subtle = "#908caa";
      text = "#e0def4";

      love = "#eb6f92";
      gold = "#f6c177";
      rose = "#ea9a97";
      pine = "#3e8fb0";
      foam = "#9ccfd8";
      iris = "#c4a7e7";
      leaf = "#95b1ac";

      highlight_low = "#2a283e";
      highlight_med = "#44415a";
      highlight_high = "#56526e";

      bg = base;
      bg_alt = surface;
      fg = text;
      fg_alt = subtle;
      comment = muted;
      red = love;
      green = leaf;
      yellow = gold;
      blue = pine;
      purple = iris;
      orange = rose;
      cyan = foam;
      teal = foam;
      accent = iris;
      accent_dim = overlay;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
