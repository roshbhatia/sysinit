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
    gorgoroth = utils.validatePalette rec {
      base00 = "#000000";
      base01 = "#121212";
      base02 = "#222222";
      base03 = "#555555";
      base04 = "#aaaaaa";
      base05 = "#c1c1c1";
      base06 = "#bbbbbb";
      base07 = "#d0d0d0";
      base08 = "#cc6666";
      base09 = "#de935f";
      base0A = "#f0c674";
      base0B = "#a5c25a";
      base0C = "#8abeb7";
      base0D = "#81a2be";
      base0E = "#b294bb";
      base0F = "#444444";

      base = base00;
      overlay = base03;
      bg = base00;
      bg_alt = base01;
      surface = base02;
      surface_alt = base03;
      text = base05;
      fg = base05;
      fg_alt = base04;
      comment = base03;

      red = base08;
      orange = base09;
      yellow = base0A;
      green = base0B;
      cyan = base0C;
      blue = base0D;
      purple = base0E;
      magenta = "#b777e0";
      teal = "#5e8d87";
      brown = "#a88654";
      pink = "#d0879f";
      lime = "#a5b76e";

      red_vibrant = "#d47373";
      orange_vibrant = "#e69763";
      yellow_vibrant = "#f0d074";
      green_vibrant = "#adc964";
      blue_vibrant = "#8dabc3";
      cyan_vibrant = "#8fc0b7";

      accent = base0D;
      accent_dim = base02;
      border_active = base0D;
      border_inactive = base03;
      border_focus = base0C;

      cursor_line_highlight = "#1a1a1a";
      cursor_grey = base03;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
