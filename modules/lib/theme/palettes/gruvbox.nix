{ lib, ... }:

with lib;

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
    author = "morhetz";
    homepage = "https://github.com/morhetz/gruvbox";
  };

  palettes = {
    dark = utils.validatePalette {

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

      base = "#282828";
      bg = "#282828";
      bg_alt = "#1d2021";
      surface = "#3c3836";
      surface_alt = "#504945";
      text = "#ebdbb2";
      fg = "#ebdbb2";
      fg_alt = "#d5c4a1";
      comment = "#928374";
      cyan = "#8ec07c";
      teal = "#8ec07c";
      accent = "#83a598";
      accent_dim = "#3c3836";
    };

    light = utils.validatePalette {

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

      base = "#fbf1c7";
      bg = "#fbf1c7";
      bg_alt = "#f9f5d7";
      surface = "#ebdbb2";
      surface_alt = "#d5c4a1";
      text = "#3c3836";
      fg = "#3c3836";
      fg_alt = "#504945";
      comment = "#928374";
      cyan = "#689d6a";
      teal = "#689d6a";
      accent = "#458588";
      accent_dim = "#ebdbb2";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      dark = "Gruvbox dark, hard (base16)";
      light = "Gruvbox light, hard (base16)";
    };

    neovim = {
      plugin = "ellisonleao/gruvbox.nvim";
      name = "gruvbox";
      setup = "gruvbox";
      colorscheme = _variant: "gruvbox";
    };

    ghostty = {
      dark = "GruvboxDark";
      light = "GruvboxLight";
    };
    bat = variant: "gruvbox-${variant}";
    delta = variant: "gruvbox-${variant}";
    atuin = variant: "gruvbox-${variant}";
    vivid = variant: "gruvbox-${variant}";
    helix = _variant: "gruvbox";
    nushell = variant: "gruvbox-${variant}.nu";
    k9s = variant: "gruvbox-${variant}";

    sketchybar = {
      background = palettes.dark.bg;
      foreground = palettes.dark.fg;
      accent = palettes.dark.blue;
      warning = palettes.dark.yellow;
      success = palettes.dark.green;
      error = palettes.dark.red;
      info = palettes.dark.aqua;
      muted = palettes.dark.gray;
      highlight = palettes.dark.orange;
    };

    zellij = variant: "gruvbox-${variant}";
  };

}
