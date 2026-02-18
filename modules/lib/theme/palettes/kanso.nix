{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Kanso";
    id = "kanso";
    variants = [
      "zen"
      "ink"
      "mist"
      "pearl"
    ];
    supports = [
      "light"
      "dark"
    ];
    appearanceMapping = {
      light = "pearl";
      dark = "ink";
    };
    author = "webhooked";
    homepage = "https://github.com/webhooked/kanso.nvim";
  };

  palettes = {
    zen = utils.validatePalette rec {
      bg0 = "#0a0e27";
      bg1 = "#0f1335";
      bg2 = "#16193b";
      bg3 = "#1e2149";

      fg0 = "#e0def4";
      fg1 = "#d0cde9";
      fg2 = "#b8b5d4";

      comment = "#6e6a86";

      red = "#eb6f92";
      orange = "#f6a192";
      yellow = "#ebbf83";
      green = "#a8d582";
      cyan = "#6ba3be";
      blue = "#7ba8e8";
      purple = "#c596c7";
      pink = "#eb6f92";

      base = bg1;
      bg = bg1;
      bg_alt = bg0;
      surface = bg2;
      surface_alt = bg3;
      text = fg0;
      subtext1 = fg1;
      subtext0 = fg2;
      fg = fg0;
      fg_alt = fg1;
      accent = blue;
      accent_dim = bg2;
    };

    ink = utils.validatePalette rec {
      bg0 = "#0d0c0c";
      bg1 = "#12120f";
      bg2 = "#1d1c19";
      bg3 = "#262520";

      fg0 = "#d4d1c3";
      fg1 = "#c8c5b8";
      fg2 = "#b3aca0";

      comment = "#7d7d68";

      red = "#dc5d5d";
      orange = "#d8953d";
      yellow = "#d8c46f";
      green = "#9b9b6b";
      cyan = "#7a9898";
      blue = "#7a8db2";
      purple = "#9b8b9b";
      pink = "#d4829d";

      base = bg1;
      bg = bg1;
      bg_alt = bg0;
      surface = bg2;
      surface_alt = bg3;
      text = fg0;
      subtext1 = fg1;
      subtext0 = fg2;
      fg = fg0;
      fg_alt = fg1;
      accent = blue;
      accent_dim = bg2;
    };

    mist = utils.validatePalette rec {
      bg0 = "#1a1f2e";
      bg1 = "#1f2433";
      bg2 = "#282d3c";
      bg3 = "#323849";

      fg0 = "#c4c7d1";
      fg1 = "#b3b6c0";
      fg2 = "#a1a5af";

      comment = "#6f7582";

      red = "#d17c7c";
      orange = "#d49f7d";
      yellow = "#d9c87f";
      green = "#8fa892";
      cyan = "#83a4a8";
      blue = "#7fa3cb";
      purple = "#a192a8";
      pink = "#d484a0";

      base = bg1;
      bg = bg1;
      bg_alt = bg0;
      surface = bg2;
      surface_alt = bg3;
      text = fg0;
      subtext1 = fg1;
      subtext0 = fg2;
      fg = fg0;
      fg_alt = fg1;
      accent = blue;
      accent_dim = bg2;
    };

    pearl = utils.validatePalette rec {
      bg0 = "#f8f7f3";
      bg1 = "#ede9e3";
      bg2 = "#e3ddd3";
      bg3 = "#d9d2c7";

      fg0 = "#2a2a2a";
      fg1 = "#3a3a3a";
      fg2 = "#5a5a5a";

      comment = "#999999";

      red = "#c1656c";
      orange = "#b8743c";
      yellow = "#997e48";
      green = "#527249";
      cyan = "#5a7b7d";
      blue = "#5a7e96";
      purple = "#6d5b7f";
      pink = "#a85d7e";

      base = bg1;
      bg = bg1;
      bg_alt = bg0;
      surface = bg2;
      surface_alt = bg3;
      text = fg0;
      subtext1 = fg1;
      subtext0 = fg2;
      fg = fg0;
      fg_alt = fg1;
      accent = blue;
      accent_dim = bg2;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
