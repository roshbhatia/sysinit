{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Monokai";
    id = "monokai";
    variants = [
      "dark"
      "light"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light";
      dark = "dark";
    };
    author = "Wimer Hazenberg";
    homepage = "https://monokai.pro/";
  };

  palettes = {
    dark = utils.validatePalette rec {
      bg = "#272822";
      bg_alt = "#3e3d32";
      surface = "#3e3d32";
      surface_alt = "#49483e";
      overlay = "#49483e";

      fg = "#f8f8f2";
      comment = "#75715e";
      text = "#f8f8f2";
      subtext1 = "#a6a6a6";
      subtext0 = "#75715e";

      red = "#f92672";
      orange = "#fd971f";
      yellow = "#e6db74";
      green = "#a6e22e";
      cyan = "#66d9ef";
      blue = "#66d9ef";
      purple = "#ae81ff";
      magenta = "#f92672";
      pink = "#f92672";
      brown = "#75715e";

      red_vibrant = "#ff5580";
      orange_vibrant = "#ffb86d";
      yellow_vibrant = "#ffff87";
      green_vibrant = "#b6e354";
      blue_vibrant = "#66d9ff";
      cyan_vibrant = "#66d9ff";

      base = bg;
      fg_alt = subtext1;
      accent = blue;
      accent_dim = overlay;
    };

    light = utils.validatePalette rec {
      bg = "#fafafa";
      bg_alt = "#f5f5f5";
      surface = "#f5f5f5";
      surface_alt = "#eff0eb";
      overlay = "#eff0eb";

      fg = "#272822";
      comment = "#8f908a";
      text = "#272822";
      subtext1 = "#555555";
      subtext0 = "#8f908a";

      red = "#d9005e";
      orange = "#d9734d";
      yellow = "#a6994d";
      green = "#548d4d";
      cyan = "#0087b3";
      blue = "#0087b3";
      purple = "#5a5dd9";
      magenta = "#d9005e";
      pink = "#d9005e";
      brown = "#8f908a";

      red_vibrant = "#e60047";
      orange_vibrant = "#e8743b";
      yellow_vibrant = "#b39e3d";
      green_vibrant = "#3d7d3d";
      blue_vibrant = "#006b9e";
      cyan_vibrant = "#006b9e";

      base = bg;
      fg_alt = subtext1;
      accent = blue;
      accent_dim = overlay;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
