{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Catppuccin";
    id = "catppuccin";
    variants = [
      "latte"
      "macchiato"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "latte";
      dark = "macchiato";
    };
    author = "Catppuccin";
    homepage = "https://github.com/catppuccin/catppuccin";
  };

  palettes = {
    latte = utils.validatePalette rec {
      base = "#eff1f5";
      mantle = "#e6e9ef";
      crust = "#dce0e8";

      surface = "#ccd0da";
      surface0 = "#ccd0da";
      surface1 = "#bcc0cc";
      surface2 = "#acb0be";
      surface_alt = surface1;

      overlay = surface1;
      overlay0 = "#9ca0b0";
      overlay1 = "#8c8fa1";
      overlay2 = "#7c7f93";

      text = "#4c4f69";
      subtext0 = "#6c6f85";
      subtext1 = "#5c5f77";

      bg = base;
      bg_alt = surface;
      bg1 = surface1;
      fg = text;
      fg_alt = subtext1;
      comment = overlay0;
      subtle = overlay1;
      muted = overlay0;

      highlight_low = surface;
      highlight_med = surface1;
      highlight_high = surface2;

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
      purple = mauve;
      orange = peach;
      cyan = teal;
      magenta = pink;

      accent = blue;
      accent_secondary = teal;
      accent_tertiary = mauve;
      accent_dim = surface1;

      # Base16 colors for stylix
      base00 = base;
      base01 = mantle;
      base02 = surface;
      base03 = overlay0;
      base04 = overlay1;
      base05 = text;
      base06 = subtext1;
      base07 = crust;
      base08 = red;
      base09 = peach;
      base0A = yellow;
      base0B = green;
      base0C = teal;
      base0D = blue;
      base0E = mauve;
      base0F = rosewater;
    };

    macchiato = utils.validatePalette rec {
      base = "#24273a";
      mantle = "#1e2030";
      crust = "#181926";

      surface = "#363a4f";
      surface0 = "#363a4f";
      surface1 = "#494d64";
      surface2 = "#5b6078";
      surface_alt = surface1;

      overlay = surface1;
      overlay0 = "#6e738d";
      overlay1 = "#8087a2";
      overlay2 = "#939ab7";

      text = "#cad3f5";
      subtext0 = "#a5adcb";
      subtext1 = "#b8c0e0";

      bg = base;
      bg_alt = surface;
      bg1 = surface1;
      fg = text;
      fg_alt = subtext1;
      comment = overlay0;
      subtle = overlay1;
      muted = overlay0;

      highlight_low = surface;
      highlight_med = surface1;
      highlight_high = surface2;

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
      purple = mauve;
      orange = peach;
      cyan = teal;
      magenta = pink;

      accent = blue;
      accent_secondary = teal;
      accent_tertiary = mauve;
      accent_dim = surface1;

      # Base16 colors for stylix
      base00 = base;
      base01 = mantle;
      base02 = surface;
      base03 = overlay0;
      base04 = overlay1;
      base05 = text;
      base06 = subtext1;
      base07 = crust;
      base08 = red;
      base09 = peach;
      base0A = yellow;
      base0B = green;
      base0C = teal;
      base0D = blue;
      base0E = mauve;
      base0F = rosewater;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
