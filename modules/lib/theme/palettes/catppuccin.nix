{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Catppuccin";
    id = "catppuccin";
    variants = [
      "macchiato"
    ];
    supports = [
      "dark"
    ];
    appearanceMapping = {
      light = null;
      dark = "macchiato";
    };
    author = "Catppuccin";
    homepage = "https://github.com/catppuccin/catppuccin";
  };

  palettes = {
    macchiato = utils.validatePalette {
      # Core background colors
      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";

      # Surface colors (for UI elements)
      surface = "#363a4f";
      surface0 = "#363a4f";
      surface1 = "#494d64";
      surface2 = "#5b6078";
      surface_alt = "#494d64";

      # Overlay colors (for floating elements)
      overlay = "#494d64";
      overlay0 = "#6e738d";
      overlay1 = "#8087a2";
      overlay2 = "#939ab7";

      # Text colors
      text = "#cad3f5";
      subtext0 = "#a5adcb";
      subtext1 = "#b8c0e0";

      # Semantic aliases for compatibility
      bg = "#24273a";
      bg_alt = "#363a4f";
      bg1 = "#494d64";
      fg = "#cad3f5";
      fg_alt = "#b8c0e0";
      comment = "#6e738d";
      subtle = "#8087a2";
      muted = "#6e738d";

      # Highlight colors for selections
      highlight_low = "#363a4f";
      highlight_med = "#494d64";
      highlight_high = "#5b6078";

      # Palette colors
      rosewater = "#f4dbd6";
      flamingo = "#f0c6c6";
      pink = "#f5bde6";
      mauve = "#c6a0f6";
      red = "#ed8796";
      maroon = "#ee99a0";
      peach = "#f5a97f";
      yellow = "#eed49f";
      green = "#a6da95";
      teal = "#8bd5ca";
      sky = "#91d7e3";
      sapphire = "#7dc4e4";
      blue = "#8aadf4";
      lavender = "#b7bdf8";
      purple = "#c6a0f6";
      orange = "#f5a97f";
      cyan = "#8bd5ca";
      magenta = "#f5bde6";

      # Accent colors
      accent = "#8aadf4";
      accent_secondary = "#8bd5ca";
      accent_tertiary = "#c6a0f6";
      accent_dim = "#494d64";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      macchiato = "Catppuccin Macchiato";
    };

    neovim = {
      plugin = "catppuccin/nvim";
      name = "catppuccin";
      setup = "catppuccin";
      colorscheme = "catppuccin";
    };

    bat = variant: "catppuccin-${variant}";
    delta = variant: "catppuccin-${variant}";
    atuin = variant: "catppuccin-${variant}";
    vivid = variant: "catppuccin-${variant}";
    helix = variant: "catppuccin_${variant}";
    k9s = variant: "catppuccin-${variant}";
    opencode = "catppuccin";

    sketchybar = {
      background = palettes.macchiato.base;
      foreground = palettes.macchiato.text;
      accent = palettes.macchiato.accent;
      warning = palettes.macchiato.yellow;
      success = palettes.macchiato.green;
      error = palettes.macchiato.red;
      info = palettes.macchiato.blue;
      muted = palettes.macchiato.muted;
      highlight = palettes.macchiato.pink;
    };
  };
}
