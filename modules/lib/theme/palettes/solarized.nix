{ lib, ... }:

with lib;

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
    author = "Ethan Schoonover";
    homepage = "https://ethanschoonover.com/solarized/";
  };

  palettes = {
    dark = utils.validatePalette {

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

      base = "#002b36";
      bg = "#002b36";
      bg_alt = "#073642";
      surface = "#073642";
      surface_alt = "#586e75";
      text = "#839496";
      fg = "#839496";
      fg_alt = "#657b83";
      comment = "#586e75";
      purple = "#6c71c4";
      teal = "#2aa198";
      accent = "#268bd2";
      accent_dim = "#073642";
    };

    light = utils.validatePalette {

      base03 = "#fdf6e3";
      base02 = "#eee8d5";
      base01 = "#93a1a1";
      base00 = "#839496";
      base0 = "#657b83";
      base1 = "#586e75";
      base2 = "#073642";
      base3 = "#002b36";

      yellow = "#b58900";
      orange = "#cb4b16";
      red = "#dc322f";
      magenta = "#d33682";
      violet = "#6c71c4";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";

      base = "#fdf6e3";
      bg = "#fdf6e3";
      bg_alt = "#eee8d5";
      surface = "#eee8d5";
      surface_alt = "#93a1a1";
      text = "#657b83";
      fg = "#657b83";
      fg_alt = "#839496";
      comment = "#93a1a1";
      purple = "#6c71c4";
      teal = "#2aa198";
      accent = "#268bd2";
      accent_dim = "#eee8d5";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      dark = "Solarized Dark Higher Contrast (Gogh)";
      light = "Solarized Light (Gogh)";
    };

    neovim = {
      plugin = "craftzdog/solarized-osaka.nvim";
      name = "solarized-osaka";
      setup = "solarized-osaka";
      colorscheme = _variant: "solarized-osaka";
    };

    ghostty = {
      dark = "Solarized Dark - Patched";
      light = "iTerm2 Solarized Light";
    };
    bat = variant: "solarized-${variant}";
    delta = variant: "solarized-${variant}";
    atuin = variant: "solarized-${variant}";
    k9s = variant: "solarized-${variant}";
    vivid = variant: "solarized-${variant}";
    helix = variant: "solarized_${variant}";
    nushell = variant: "solarized-${variant}.nu";

    sketchybar = {
      background = palettes.dark.base03;
      foreground = palettes.dark.base0;
      accent = palettes.dark.blue;
      warning = palettes.dark.yellow;
      success = palettes.dark.green;
      error = palettes.dark.red;
      info = palettes.dark.cyan;
      muted = palettes.dark.base01;
      highlight = palettes.dark.magenta;
    };

    zellij = variant: "solarized-${variant}";
  };
}
