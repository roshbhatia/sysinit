{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Catppuccin";
    id = "catppuccin";
    variants = [
      "macchiato"
      "frappe"
      "latte"
      "mocha"
    ];
    supports = [
      "dark"
      "light"
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

    frappe = utils.validatePalette {

      base = "#303446";
      mantle = "#292c3c";
      crust = "#232634";

      surface0 = "#414559";
      surface1 = "#51576d";
      surface2 = "#626880";

      overlay0 = "#737994";
      overlay1 = "#838ba7";
      overlay2 = "#949cbb";

      text = "#c6d0f5";
      subtext0 = "#a5adce";
      subtext1 = "#b5bfe2";

      rosewater = "#f2d5cf";
      flamingo = "#eebebe";
      pink = "#f4b8e4";
      mauve = "#ca9ee6";
      red = "#e78284";
      maroon = "#ea999c";
      peach = "#ef9f76";
      yellow = "#e5c890";
      green = "#a6d189";
      teal = "#81c8be";
      sky = "#99d1db";
      sapphire = "#85c1dc";
      blue = "#8caaee";
      lavender = "#babbf1";

      accent = "#8caaee";
      accent_dim = "#51576d";
    };

    latte = utils.validatePalette {

      base = "#eff1f5";
      mantle = "#e6e9ef";
      crust = "#dce0e8";

      surface0 = "#ccd0da";
      surface1 = "#bcc0cc";
      surface2 = "#acb0be";

      overlay0 = "#9ca0b0";
      overlay1 = "#8c8fa1";
      overlay2 = "#7c7f93";

      text = "#4c4f69";
      subtext0 = "#6c6f85";
      subtext1 = "#5c5f77";

      rosewater = "#dc8a78";
      flamingo = "#dd7878";
      pink = "#ea76cb";
      mauve = "#8839ef";
      red = "#d20f39";
      maroon = "#e64553";
      peach = "#fe640b";
      yellow = "#df8e1d";
      green = "#40a02b";
      teal = "#179299";
      sky = "#04a5e5";
      sapphire = "#209fb5";
      blue = "#1e66f5";
      lavender = "#7287fd";

      accent = "#1e66f5";
      accent_dim = "#bcc0cc";
    };

    mocha = utils.validatePalette {

      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";

      surface0 = "#313244";
      surface1 = "#45475a";
      surface2 = "#585b70";

      overlay0 = "#6c7086";
      overlay1 = "#7f849c";
      overlay2 = "#9399b2";

      text = "#cdd6f4";
      subtext0 = "#a6adc8";
      subtext1 = "#bac2de";

      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";

      accent = "#89b4fa";
      accent_dim = "#45475a";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      macchiato = "Catppuccin Macchiato";
      frappe = "Catppuccin Frappe";
      latte = "Catppuccin Latte";
      mocha = "Catppuccin Mocha";
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
  };
}
