{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Rosé Pine";
    id = "rose-pine";
    variants = [
      "moon"
    ];
    supports = [
      "dark"
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

  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      moon = "Rouge 2";
    };

    neovim = {
      plugin = "cdmill/neomodern.nvim";
      name = "neomodern";
      setup = "neomodern";
      colorscheme = _variant: "roseprime";
    };

    bat = variant: "rose-pine-${variant}";
    delta = variant: "rose-pine-${variant}";
    k9s = variant: "rose-pine-${variant}";
    atuin = variant: "rose-pine-${variant}";
    vivid = variant: "rose-pine-${variant}";
    helix = variant: "rose_pine_${variant}";
    nushell = variant: "rose-pine-${variant}.nu";

    sketchybar = {
      background = palettes.moon.base;
      foreground = palettes.moon.text;
      accent = palettes.moon.iris;
      warning = palettes.moon.gold;
      success = palettes.moon.foam;
      error = palettes.moon.love;
      info = palettes.moon.pine;
      muted = palettes.moon.muted;
      highlight = palettes.moon.rose;
    };
  };
}
