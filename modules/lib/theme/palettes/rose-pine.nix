{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Rosé Pine";
    id = "rose-pine";
    variants = [
      "moon"
      "dawn"
      "main"
    ];
    supports = [
      "dark"
      "light"
    ];
    author = "Rosé Pine";
    homepage = "https://github.com/rose-pine/rose-pine";
  };

  palettes = {
    moon = utils.validatePalette {

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

      highlight_low = "#2a283e";
      highlight_med = "#44415a";
      highlight_high = "#56526e";

      bg = "#232136";
      bg_alt = "#2a273f";
      fg = "#e0def4";
      fg_alt = "#908caa";
      comment = "#6e6a86";
      red = "#eb6f92";
      green = "#3e8fb0";
      yellow = "#f6c177";
      blue = "#3e8fb0";
      purple = "#c4a7e7";
      orange = "#ea9a97";
      cyan = "#9ccfd8";
      teal = "#9ccfd8";
      accent = "#c4a7e7";
      accent_dim = "#393552";
    };

    dawn = utils.validatePalette {

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

      highlight_low = "#f4ede8";
      highlight_med = "#dfdad9";
      highlight_high = "#cecacd";

      bg = "#faf4ed";
      bg_alt = "#fffaf3";
      fg = "#575279";
      fg_alt = "#797593";
      comment = "#9893a5";
      red = "#b4637a";
      green = "#286983";
      yellow = "#ea9d34";
      blue = "#286983";
      purple = "#907aa9";
      orange = "#d7827e";
      cyan = "#56949f";
      teal = "#56949f";
      accent = "#907aa9";
      accent_dim = "#f2e9e1";
    };

    main = utils.validatePalette {

      base = "#191724";
      surface = "#1f1d2e";
      overlay = "#26233a";

      muted = "#6e6a86";
      subtle = "#908caa";
      text = "#e0def4";

      love = "#eb6f92";
      gold = "#f6c177";
      rose = "#ebbcba";
      pine = "#31748f";
      foam = "#9ccfd8";
      iris = "#c4a7e7";

      highlight_low = "#21202e";
      highlight_med = "#403d52";
      highlight_high = "#524f67";

      bg = "#191724";
      bg_alt = "#1f1d2e";
      fg = "#e0def4";
      fg_alt = "#908caa";
      comment = "#6e6a86";
      red = "#eb6f92";
      green = "#31748f";
      yellow = "#f6c177";
      blue = "#31748f";
      purple = "#c4a7e7";
      orange = "#ebbcba";
      cyan = "#9ccfd8";
      teal = "#9ccfd8";
      accent = "#c4a7e7";
      accent_dim = "#26233a";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      moon = "Rosé Pine (Gogh)";
      dawn = "Rosé Pine Dawn (Gogh)";
      main = "Rosé Pine (Gogh)";
    };

    neovim = {
      plugin = "cdmill/neomodern.nvim";
      name = "neomodern";
      setup = "neomodern";
      colorscheme = variant: "roseprime";
    };

    bat = variant: "rose-pine-${variant}";
    delta = variant: "rose-pine-${variant}";
    atuin = variant: "rose-pine-${variant}";
    vivid = variant: "rose-pine-${variant}";
    helix = variant: "rose_pine_${variant}";
    nushell = variant: "rose-pine-${variant}.nu";
  };
}
