{ lib, ... }:

with lib;

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
    author = "Catppuccin";
    homepage = "https://github.com/catppuccin/catppuccin";
  };

  palettes = {
    macchiato = utils.validatePalette {

      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";

      surface0 = "#363a4f";
      surface1 = "#494d64";
      surface2 = "#5b6078";

      overlay0 = "#6e738d";
      overlay1 = "#8087a2";
      overlay2 = "#939ab7";

      text = "#cad3f5";
      subtext0 = "#a5adcb";
      subtext1 = "#b8c0e0";

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

      accent = "#8aadf4";
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
    nushell = variant: "catppuccin-${variant}.nu";
    k9s = variant: "catppuccin-${variant}";

    sketchybar = {
      background = palettes.macchiato.base;
      foreground = palettes.macchiato.text;
      accent = palettes.macchiato.accent;
      warning = palettes.macchiato.yellow;
      success = palettes.macchiato.green;
      error = palettes.macchiato.red;
      info = palettes.macchiato.blue;
      muted = palettes.macchiato.subtext0;
      highlight = palettes.macchiato.pink;
    };

    zellij = {
      macchiato = "catppuccin-macchiato";
    };
  };
}
