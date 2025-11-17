{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Everforest";
    id = "everforest";
    variants = [
      "dark-hard"
      "dark-medium"
      "dark-soft"
      "light-hard"
      "light-medium"
      "light-soft"
    ];
    supports = [
      "dark"
      "light"
    ];
    appearanceMapping = {
      light = "light-medium";
      dark = "dark-medium";
    };
    author = "sainnhe";
    homepage = "https://github.com/sainnhe/everforest";
  };

  palettes = {
    # Dark Hard variant
    dark-hard = utils.validatePalette {
      # Background colors
      bg_dim = "#1E2326";
      bg0 = "#272E33";
      bg1 = "#2E383C";
      bg2 = "#374145";
      bg3 = "#414B50";
      bg4 = "#495156";
      bg5 = "#4F5B58";

      # Visual selection
      bg_visual = "#4C3743";

      # Semantic backgrounds
      bg_red = "#493B40";
      bg_yellow = "#45443c";
      bg_green = "#3C4841";
      bg_blue = "#384B55";
      bg_purple = "#463F48";

      # Foreground colors
      fg = "#D3C6AA";

      # Accent colors
      red = "#E67E80";
      orange = "#E69875";
      yellow = "#DBBC7F";
      green = "#A7C080";
      aqua = "#83C092";
      blue = "#7FBBB3";
      purple = "#D699B6";

      # Grey colors
      grey0 = "#7A8478";
      grey1 = "#859289";
      grey2 = "#9DA9A0";

      # Statusline colors
      statusline1 = "#A7C080";
      statusline2 = "#D3C6AA";
      statusline3 = "#E67E80";

      # Compatibility aliases
      base = "#272E33";
      bg = "#272E33";
      bg_alt = "#1E2326";
      surface = "#2E383C";
      surface_alt = "#374145";
      text = "#D3C6AA";
      fg_alt = "#859289";
      comment = "#859289";
      cyan = "#83C092";
      teal = "#83C092";
      accent = "#A7C080";
      accent_dim = "#2E383C";
    };

    # Dark Medium variant (default dark)
    dark-medium = utils.validatePalette {
      # Background colors
      bg_dim = "#232A2E";
      bg0 = "#2D353B";
      bg1 = "#343F44";
      bg2 = "#3D484D";
      bg3 = "#475258";
      bg4 = "#4F585E";
      bg5 = "#56635f";

      # Visual selection
      bg_visual = "#543A48";

      # Semantic backgrounds
      bg_red = "#514045";
      bg_yellow = "#4D4C43";
      bg_green = "#425047";
      bg_blue = "#3A515D";
      bg_purple = "#4A444E";

      # Foreground colors
      fg = "#D3C6AA";

      # Accent colors
      red = "#E67E80";
      orange = "#E69875";
      yellow = "#DBBC7F";
      green = "#A7C080";
      aqua = "#83C092";
      blue = "#7FBBB3";
      purple = "#D699B6";

      # Grey colors
      grey0 = "#7A8478";
      grey1 = "#859289";
      grey2 = "#9DA9A0";

      # Statusline colors
      statusline1 = "#A7C080";
      statusline2 = "#D3C6AA";
      statusline3 = "#E67E80";

      # Compatibility aliases
      base = "#2D353B";
      bg = "#2D353B";
      bg_alt = "#232A2E";
      surface = "#343F44";
      surface_alt = "#3D484D";
      text = "#D3C6AA";
      fg_alt = "#859289";
      comment = "#859289";
      cyan = "#83C092";
      teal = "#83C092";
      accent = "#A7C080";
      accent_dim = "#343F44";
    };

    # Dark Soft variant
    dark-soft = utils.validatePalette {
      # Background colors
      bg_dim = "#293136";
      bg0 = "#333C43";
      bg1 = "#3A464C";
      bg2 = "#434F55";
      bg3 = "#4D5960";
      bg4 = "#555F66";
      bg5 = "#5D6B66";

      # Visual selection
      bg_visual = "#5C3F4F";

      # Semantic backgrounds
      bg_red = "#59464C";
      bg_yellow = "#55544A";
      bg_green = "#48584E";
      bg_blue = "#3F5865";
      bg_purple = "#4E4953";

      # Foreground colors
      fg = "#D3C6AA";

      # Accent colors
      red = "#E67E80";
      orange = "#E69875";
      yellow = "#DBBC7F";
      green = "#A7C080";
      aqua = "#83C092";
      blue = "#7FBBB3";
      purple = "#D699B6";

      # Grey colors
      grey0 = "#7A8478";
      grey1 = "#859289";
      grey2 = "#9DA9A0";

      # Statusline colors
      statusline1 = "#A7C080";
      statusline2 = "#D3C6AA";
      statusline3 = "#E67E80";

      # Compatibility aliases
      base = "#333C43";
      bg = "#333C43";
      bg_alt = "#293136";
      surface = "#3A464C";
      surface_alt = "#434F55";
      text = "#D3C6AA";
      fg_alt = "#859289";
      comment = "#859289";
      cyan = "#83C092";
      teal = "#83C092";
      accent = "#A7C080";
      accent_dim = "#3A464C";
    };

    # Light Hard variant
    light-hard = utils.validatePalette {
      # Background colors
      bg_dim = "#F2EFDF";
      bg0 = "#FFFBEF";
      bg1 = "#F8F5E4";
      bg2 = "#F2EFDF";
      bg3 = "#EDEADA";
      bg4 = "#E8E5D5";
      bg5 = "#BEC5B2";

      # Visual selection
      bg_visual = "#F0F2D4";

      # Semantic backgrounds
      bg_red = "#FFE7DE";
      bg_yellow = "#FEF2D5";
      bg_green = "#F3F5D9";
      bg_blue = "#ECF5ED";
      bg_purple = "#FCECED";

      # Foreground colors
      fg = "#5C6A72";

      # Accent colors
      red = "#F85552";
      orange = "#F57D26";
      yellow = "#DFA000";
      green = "#8DA101";
      aqua = "#35A77C";
      blue = "#3A94C5";
      purple = "#DF69BA";

      # Grey colors
      grey0 = "#A6B0A0";
      grey1 = "#939F91";
      grey2 = "#829181";

      # Statusline colors
      statusline1 = "#93B259";
      statusline2 = "#708089";
      statusline3 = "#E66868";

      # Compatibility aliases
      base = "#FFFBEF";
      bg = "#FFFBEF";
      bg_alt = "#F2EFDF";
      surface = "#F8F5E4";
      surface_alt = "#F2EFDF";
      text = "#5C6A72";
      fg_alt = "#939F91";
      comment = "#939F91";
      cyan = "#35A77C";
      teal = "#35A77C";
      accent = "#8DA101";
      accent_dim = "#F8F5E4";
    };

    # Light Medium variant (default light)
    light-medium = utils.validatePalette {
      # Background colors
      bg_dim = "#EFEBD4";
      bg0 = "#FDF6E3";
      bg1 = "#F4F0D9";
      bg2 = "#EFEBD4";
      bg3 = "#E6E2CC";
      bg4 = "#E0DCC7";
      bg5 = "#BDC3AF";

      # Visual selection
      bg_visual = "#EAEDC8";

      # Semantic backgrounds
      bg_red = "#FDE3DA";
      bg_yellow = "#FAEDCD";
      bg_green = "#F0F1D2";
      bg_blue = "#E9F0E9";
      bg_purple = "#FAE8E2";

      # Foreground colors
      fg = "#5C6A72";

      # Accent colors
      red = "#F85552";
      orange = "#F57D26";
      yellow = "#DFA000";
      green = "#8DA101";
      aqua = "#35A77C";
      blue = "#3A94C5";
      purple = "#DF69BA";

      # Grey colors
      grey0 = "#A6B0A0";
      grey1 = "#939F91";
      grey2 = "#829181";

      # Statusline colors
      statusline1 = "#93B259";
      statusline2 = "#708089";
      statusline3 = "#E66868";

      # Compatibility aliases
      base = "#FDF6E3";
      bg = "#FDF6E3";
      bg_alt = "#EFEBD4";
      surface = "#F4F0D9";
      surface_alt = "#EFEBD4";
      text = "#5C6A72";
      fg_alt = "#939F91";
      comment = "#939F91";
      cyan = "#35A77C";
      teal = "#35A77C";
      accent = "#8DA101";
      accent_dim = "#F4F0D9";
    };

    # Light Soft variant
    light-soft = utils.validatePalette {
      # Background colors
      bg_dim = "#E5DFC5";
      bg0 = "#F3EAD3";
      bg1 = "#EAE4CA";
      bg2 = "#E5DFC5";
      bg3 = "#DDD8BE";
      bg4 = "#D8D3BA";
      bg5 = "#B9C0AB";

      # Visual selection
      bg_visual = "#E1E4BD";

      # Semantic backgrounds
      bg_red = "#FADBD0";
      bg_yellow = "#F1E4C5";
      bg_green = "#E5E6C5";
      bg_blue = "#E1E7DD";
      bg_purple = "#F1DDD4";

      # Foreground colors
      fg = "#5C6A72";

      # Accent colors
      red = "#F85552";
      orange = "#F57D26";
      yellow = "#DFA000";
      green = "#8DA101";
      aqua = "#35A77C";
      blue = "#3A94C5";
      purple = "#DF69BA";

      # Grey colors
      grey0 = "#A6B0A0";
      grey1 = "#939F91";
      grey2 = "#829181";

      # Statusline colors
      statusline1 = "#93B259";
      statusline2 = "#708089";
      statusline3 = "#E66868";

      # Compatibility aliases
      base = "#F3EAD3";
      bg = "#F3EAD3";
      bg_alt = "#E5DFC5";
      surface = "#EAE4CA";
      surface_alt = "#E5DFC5";
      text = "#5C6A72";
      fg_alt = "#939F91";
      comment = "#939F91";
      cyan = "#35A77C";
      teal = "#35A77C";
      accent = "#8DA101";
      accent_dim = "#EAE4CA";
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    wezterm = {
      dark-hard = "Everforest Dark Hard (Gogh)";
      dark-medium = "Everforest Dark (Gogh)";
      dark-soft = "Everforest Dark Soft (Gogh)";
      light-hard = "Everforest Light Hard (Gogh)";
      light-medium = "Everforest Light (Gogh)";
      light-soft = "Everforest Light Soft (Gogh)";
    };

    neovim = {
      plugin = "sainnhe/everforest";
      name = "everforest";
      setup = "everforest";
      colorscheme = _variant: "everforest";
    };

    bat = variant: "everforest-${variant}";
    # Explicitly using nord here
    delta = variant: "nord-${variant}";
    atuin = variant: "everforest-${variant}";
    vivid = variant: "everforest-${variant}";
    helix = _variant: "everforest";
    k9s = variant: "everforest-${variant}";
    opencode = "everforest";

    sketchybar = {
      background = palettes.dark-medium.bg0;
      foreground = palettes.dark-medium.fg;
      accent = palettes.dark-medium.green;
      warning = palettes.dark-medium.yellow;
      success = palettes.dark-medium.green;
      error = palettes.dark-medium.red;
      info = palettes.dark-medium.blue;
      muted = palettes.dark-medium.grey1;
      highlight = palettes.dark-medium.orange;
    };
  };
}
