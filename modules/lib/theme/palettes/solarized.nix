{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
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
      # Base colors
      base03 = "#002b36"; # background
      base02 = "#073642"; # background highlights
      base01 = "#586e75"; # comments / secondary content
      base00 = "#657b83"; # body text / default code / primary content
      base0 = "#839496"; # primary content
      base1 = "#93a1a1"; # optional emphasized content
      base2 = "#eee8d5"; # background highlights (light theme)
      base3 = "#fdf6e3"; # background (light theme)

      # Accent colors
      yellow = "#b58900";
      orange = "#cb4b16";
      red = "#dc322f";
      magenta = "#d33682";
      violet = "#6c71c4";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";

      # Semantic aliases
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
      # Base colors (light theme - swapped from dark)
      base03 = "#fdf6e3"; # background
      base02 = "#eee8d5"; # background highlights
      base01 = "#93a1a1"; # comments / secondary content
      base00 = "#839496"; # body text / default code / primary content
      base0 = "#657b83"; # primary content
      base1 = "#586e75"; # optional emphasized content
      base2 = "#073642"; # background highlights (dark theme)
      base3 = "#002b36"; # background (dark theme)

      # Accent colors (same)
      yellow = "#b58900";
      orange = "#cb4b16";
      red = "#dc322f";
      magenta = "#d33682";
      violet = "#6c71c4";
      blue = "#268bd2";
      cyan = "#2aa198";
      green = "#859900";

      # Semantic aliases
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
      colorscheme = variant: "solarized-osaka";
    };

    bat = variant: "solarized-${variant}";
    delta = variant: "solarized-${variant}";
    atuin = variant: "solarized-${variant}";
    vivid = variant: "solarized-${variant}";
    helix = variant: "solarized_${variant}";
    nushell = variant: "solarized-${variant}.nu";
  };
}
