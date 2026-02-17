{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Nord";
    id = "nord";
    variants = [
      "default"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "default";
    };
    author = "Arctic Ice Studio";
    homepage = "https://www.nordtheme.com/";
  };

  palettes = {
    default = utils.validatePalette rec {
      nord0 = "#2e3440";
      nord1 = "#3b4252";
      nord2 = "#434c5e";
      nord3 = "#4c566a";

      nord4 = "#d8dee9";
      nord5 = "#e5e9f0";
      nord6 = "#eceff4";

      nord7 = "#8fbcbb";
      nord8 = "#88c0d0";
      nord9 = "#81a1c1";
      nord10 = "#5e81ac";

      nord11 = "#bf616a";
      nord12 = "#d08770";
      nord13 = "#ebcb8b";
      nord14 = "#a3be8c";
      nord15 = "#b48ead";

      base = nord0;
      bg = nord0;
      bg_alt = nord1;
      surface = nord2;
      surface_alt = nord3;
      text = nord6;
      subtext1 = nord5;
      subtext0 = nord4;
      fg = nord6;
      fg_alt = nord5;
      comment = nord3;
      blue = nord10;
      cyan = nord8;
      teal = nord7;
      green = nord14;
      yellow = nord13;
      orange = nord12;
      red = nord11;
      purple = nord15;
      accent = nord10;
      accent_dim = nord2;
    };

    light = utils.validatePalette rec {
      nord0 = "#2e3440";
      nord1 = "#3b4252";
      nord2 = "#434c5e";
      nord3 = "#4c566a";

      nord4 = "#d8dee9";
      nord5 = "#e5e9f0";
      nord6 = "#eceff4";

      nord7 = "#8fbcbb";
      nord8 = "#88c0d0";
      nord9 = "#81a1c1";
      nord10 = "#5e81ac";

      nord11 = "#bf616a";
      nord12 = "#d08770";
      nord13 = "#ebcb8b";
      nord14 = "#a3be8c";
      nord15 = "#b48ead";

      base = nord6;
      bg = nord6;
      bg_alt = nord5;
      surface = nord5;
      surface_alt = nord4;
      text = nord0;
      subtext1 = nord1;
      subtext0 = nord2;
      fg = nord0;
      fg_alt = nord2;
      comment = nord4;
      blue = nord8;
      cyan = nord7;
      teal = nord7;
      green = nord14;
      yellow = nord13;
      orange = nord12;
      red = nord11;
      purple = nord15;
      accent = nord8;
      accent_dim = nord5;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
