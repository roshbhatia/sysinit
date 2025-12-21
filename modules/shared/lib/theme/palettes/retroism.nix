{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Retroism";
    id = "retroism";
    variants = [
      "dark"
      "amber"
      "green"
    ];
    supports = [
      "dark"
    ];
    appearanceMapping = {
      dark = "dark";
    };
    author = "diinki";
    homepage = "https://github.com/diinki/linux-retroism";
  };

  palettes = {
    # Default dark theme with classic CRT monitor aesthetic
    dark = utils.validatePalette rec {
      # Base colors - dark background typical of 80s/90s systems
      bg0_h = "#0a0e27";
      bg0 = "#0d1117";
      bg0_s = "#101420";
      bg1 = "#161b22";
      bg2 = "#21262d";
      bg3 = "#30363d";
      bg4 = "#484f58";

      # Phosphor green foreground (classic CRT green)
      fg0 = "#39ff14";
      fg1 = "#00ff41";
      fg2 = "#00e676";
      fg3 = "#00c853";
      fg4 = "#7bb661";

      # Cyan/blue accents
      cyan = "#00e5ff";
      cyan_dim = "#0097a7";

      # Purple/magenta accents
      purple = "#e040fb";
      purple_dim = "#9c27b0";

      # Signal colors
      red = "#ff0000";
      green = "#00ff00";
      yellow = "#ffff00";
      blue = "#0088ff";
      orange = "#ff8800";
      aqua = "#00ffff";

      # Semantic
      gray = "#666666";
      base = bg0;
      bg = bg0;
      bg_alt = bg0_h;
      surface = bg1;
      surface_alt = bg2;
      text = fg0;
      subtext1 = fg2;
      subtext0 = fg3;
      fg = fg0;
      fg_alt = fg2;
      comment = gray;
      teal = aqua;
      accent = cyan;
      accent_dim = cyan_dim;
    };

    # Amber monitor variant (warm CRT aesthetic)
    amber = utils.validatePalette rec {
      bg0_h = "#1a0e00";
      bg0 = "#1f1200";
      bg0_s = "#251a05";
      bg1 = "#2d1f0a";
      bg2 = "#3d2a0f";
      bg3 = "#4a3415";
      bg4 = "#5a4020";

      # Warm amber/orange phosphor
      fg0 = "#ffb90f";
      fg1 = "#ffa500";
      fg2 = "#ff8c00";
      fg3 = "#dd7700";
      fg4 = "#bb5500";

      # Muted accent colors
      cyan = "#ffcc00";
      cyan_dim = "#cc9900";

      purple = "#ff6600";
      purple_dim = "#dd4400";

      red = "#ff3300";
      green = "#ffaa00";
      yellow = "#ffff00";
      blue = "#ff7700";
      orange = "#ffb90f";
      aqua = "#ffcc00";

      gray = "#664400";
      base = bg0;
      bg = bg0;
      bg_alt = bg0_h;
      surface = bg1;
      surface_alt = bg2;
      text = fg0;
      subtext1 = fg2;
      subtext0 = fg3;
      fg = fg0;
      fg_alt = fg2;
      comment = gray;
      teal = aqua;
      accent = cyan;
      accent_dim = cyan_dim;
    };

    # White/green monochrome variant (classic computer monitor)
    green = utils.validatePalette rec {
      bg0_h = "#001a00";
      bg0 = "#001f00";
      bg0_s = "#002600";
      bg1 = "#003300";
      bg2 = "#004d00";
      bg3 = "#006600";
      bg4 = "#008000";

      # Bright phosphor green
      fg0 = "#00ff00";
      fg1 = "#00e600";
      fg2 = "#00cc00";
      fg3 = "#00b300";
      fg4 = "#009900";

      cyan = "#00ffff";
      cyan_dim = "#00cccc";

      purple = "#00ff99";
      purple_dim = "#00cc66";

      red = "#ff0000";
      green = "#00ff00";
      yellow = "#ffff00";
      blue = "#0088ff";
      orange = "#ff8800";
      aqua = "#00ffff";

      gray = "#666666";
      base = bg0;
      bg = bg0;
      bg_alt = bg0_h;
      surface = bg1;
      surface_alt = bg2;
      text = fg0;
      subtext1 = fg2;
      subtext0 = fg3;
      fg = fg0;
      fg_alt = fg2;
      comment = gray;
      teal = aqua;
      accent = cyan;
      accent_dim = cyan_dim;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
