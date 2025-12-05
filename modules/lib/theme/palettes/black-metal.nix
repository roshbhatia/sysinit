{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Black Metal";
    id = "black-metal";
    variants = [ "gorgoroth" ];
    supports = [ "dark" ];
    appearanceMapping = {
      light = null;
      dark = "gorgoroth";
    };
    author = "metalelf0";
    homepage = "https://github.com/metalelf0/base16-black-metal-scheme";
  };

  palettes = {
    # Gorgoroth variant - based on base16 Black Metal (Gorgoroth)
    # Pure black background with muted, desaturated accent colors
    gorgoroth = utils.validatePalette {
      # Base16 colors
      base00 = "#000000"; # Pure black background
      base01 = "#121212"; # Lighter black
      base02 = "#222222"; # Selection background
      base03 = "#333333"; # Comments, invisibles
      base04 = "#999999"; # Dark foreground
      base05 = "#c1c1c1"; # Default foreground
      base06 = "#999999"; # Light foreground
      base07 = "#c1c1c1"; # Lightest foreground
      base08 = "#5f8787"; # Red/Variables (muted teal)
      base09 = "#aaaaaa"; # Orange/Integers
      base0A = "#8c7f70"; # Yellow/Classes (brownish)
      base0B = "#9b8d7f"; # Green/Strings (tan)
      base0C = "#aaaaaa"; # Cyan/Support
      base0D = "#888888"; # Blue/Functions
      base0E = "#999999"; # Purple/Keywords
      base0F = "#444444"; # Deprecated/Special

      # Compatibility aliases for semantic mapping
      bg = "#000000";
      bg_alt = "#121212";
      surface = "#222222";
      surface_alt = "#333333";
      text = "#c1c1c1";
      fg = "#c1c1c1";
      fg_alt = "#999999";
      comment = "#333333";

      # Semantic colors
      red = "#5f8787";
      orange = "#aaaaaa";
      yellow = "#8c7f70";
      green = "#9b8d7f";
      cyan = "#aaaaaa";
      blue = "#888888";
      purple = "#999999";
      teal = "#aaaaaa";

      # Additional semantic mappings
      accent = "#888888";
      accent_dim = "#222222";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    # Wezterm uses base16 built-in theme
    wezterm = {
      gorgoroth = "Black Metal (Gorgoroth)";
    };

    # Neovim uses metalelf0's black-metal-theme-neovim plugin
    neovim = {
      plugin = "metalelf0/black-metal-theme-neovim";
      name = "black-metal";
      setup = "black-metal";
      colorscheme = _variant: "gorgoroth";
    };

    # Custom theme files for other tools
    bat = variant: "black-metal-${variant}";
    delta = variant: "black-metal-${variant}";
    k9s = variant: "black-metal-${variant}";
    atuin = variant: "black-metal-${variant}";
    vivid = variant: "black-metal-${variant}";
    helix = _variant: "black-metal";
    opencode = "system";

    # Sketchybar colors
    sketchybar = {
      background = palettes.gorgoroth.base00;
      foreground = palettes.gorgoroth.base05;
      accent = palettes.gorgoroth.base0D;
      warning = palettes.gorgoroth.base0A;
      success = palettes.gorgoroth.base0B;
      error = palettes.gorgoroth.base08;
      info = palettes.gorgoroth.base0D;
      muted = palettes.gorgoroth.base04;
      highlight = palettes.gorgoroth.base09;
    };
  };
}
