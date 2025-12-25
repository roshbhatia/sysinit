{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  meta = {
    name = "Tokyonight";
    id = "tokyonight";
    variants = [
      "night"
      "storm"
      "day"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "day";
      dark = "night";
    };
    author = "folke";
    homepage = "https://github.com/folke/tokyonight.nvim";
  };

  palettes = {
    night = utils.validatePalette rec {
      bg = "#1a1b26";
      bg_dark = "#16161e";
      bg_float = "#16161e";
      bg_highlight = "#292e42";
      bg_search = "#3d59a1";
      bg_visual = "#393d52";
      border = "#15202b";

      comment = "#565f89";
      fg = "#c0caf5";
      fg_dark = "#828bb8";
      fg_gutter = "#3b4261";
      fg_sidebar = "#a9b1d6";

      red = "#f7768e";
      orange = "#ff9e64";
      yellow = "#e0af68";
      green = "#9ece6a";
      cyan = "#7aa2f7";
      blue = "#7aa2f7";
      purple = "#bb9af7";
      magenta = "#bb9af7";

      # Additional colors
      git_add = "#449dab";
      git_change = "#6183bb";
      git_delete = "#914c54";
      git_ignore = "#545c7e";

      # Semantic base
      base = bg;
      surface = bg_highlight;
      overlay = bg_visual;
      text = fg;
      subtext1 = fg_dark;
      subtext0 = comment;
      accent = blue;
      accent_dim = border;

      fg_alt = fg_dark;
      bg_alt = bg_dark;
      surface_alt = bg_visual;
      teal = cyan;
    };

    storm = utils.validatePalette rec {
      bg = "#24283b";
      bg_dark = "#1f2335";
      bg_float = "#1f2335";
      bg_highlight = "#3f4859";
      bg_search = "#3d59a1";
      bg_visual = "#3e4452";
      border = "#1e202e";

      comment = "#565f89";
      fg = "#c0caf5";
      fg_dark = "#828bb8";
      fg_gutter = "#3b4261";
      fg_sidebar = "#a9b1d6";

      red = "#f7768e";
      orange = "#ff9e64";
      yellow = "#e0af68";
      green = "#9ece6a";
      cyan = "#7aa2f7";
      blue = "#7aa2f7";
      purple = "#bb9af7";
      magenta = "#bb9af7";

      git_add = "#449dab";
      git_change = "#6183bb";
      git_delete = "#914c54";
      git_ignore = "#545c7e";

      base = bg;
      surface = bg_highlight;
      overlay = bg_visual;
      text = fg;
      subtext1 = fg_dark;
      subtext0 = comment;
      accent = blue;
      accent_dim = border;

      fg_alt = fg_dark;
      bg_alt = bg_dark;
      surface_alt = bg_visual;
      inherit cyan;
      teal = cyan;
    };

    day = utils.validatePalette rec {
      bg = "#e1e2e7";
      bg_dark = "#d5d6db";
      bg_float = "#f5f5f5";
      bg_highlight = "#dfe0e5";
      bg_search = "#b3d7ff";
      bg_visual = "#d0e5f9";
      border = "#bfc8d8";

      comment = "#848cb5";
      fg = "#3b3f5c";
      fg_dark = "#6c7086";
      fg_gutter = "#b8bcce";
      fg_sidebar = "#5e6173";

      red = "#e82829";
      orange = "#d76e15";
      yellow = "#c4906b";
      green = "#587539";
      cyan = "#0184bc";
      blue = "#3d5afe";
      purple = "#5a4a9d";
      magenta = "#5a4a9d";

      git_add = "#266d6a";
      git_change = "#536582";
      git_delete = "#8c4351";
      git_ignore = "#a8a8be";

      base = bg;
      surface = bg_highlight;
      overlay = bg_visual;
      text = fg;
      subtext1 = fg_dark;
      subtext0 = comment;
      accent = blue;
      accent_dim = border;

      fg_alt = fg_dark;
      bg_alt = bg_dark;
      surface_alt = bg_visual;
      teal = cyan;
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;
}
