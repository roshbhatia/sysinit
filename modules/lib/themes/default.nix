{ ... }:

let
  palettes = {
    catppuccin = {
      macchiato = {
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

    rose-pine = {
      moon = {
        base = "#232136";
        surface = "#2a273f";
        overlay = "#393552";
        muted = "#6e6a86";
        subtle = "#908caa";
        text = "#e0def4";
        love = "#eb6f92";
        gold = "#f6c177";
        rose = "#ea9a97";
        pine = "#3e8fb0";
        blue = "#3e8fb0";
        foam = "#9ccfd8";
        iris = "#c4a7e7";
        highlight_low = "#2a283e";
        highlight_med = "#44415a";
        highlight_high = "#56526e";
        accent = "#c4a7e7";
        accent_dim = "#393552";
      };
    };

    gruvbox = {
      dark = {
        bg0_h = "#1d2021";
        bg0 = "#282828";
        bg0_s = "#32302f";
        bg1 = "#3c3836";
        bg2 = "#504945";
        bg3 = "#665c54";
        bg4 = "#7c6f64";
        fg0 = "#fbf1c7";
        fg1 = "#ebdbb2";
        fg2 = "#d5c4a1";
        fg3 = "#bdae93";
        fg4 = "#a89984";
        gray = "#928374";
        red = "#fb4934";
        green = "#b8bb26";
        yellow = "#fabd2f";
        blue = "#83a598";
        purple = "#d3869b";
        aqua = "#8ec07c";
        orange = "#fe8019";
        neutral_red = "#cc241d";
        neutral_green = "#98971a";
        neutral_yellow = "#d79921";
        neutral_blue = "#458588";
        neutral_purple = "#b16286";
        neutral_aqua = "#689d6a";
        dark_red = "#421e1e";
        dark_green = "#2d3319";
        dark_yellow = "#4e3e1e";
        dark_blue = "#2d4650";
        dark_purple = "#4a3650";
        dark_aqua = "#36473a";
        accent = "#83a598";
        accent_dim = "#3c3836";
      };
    };

    solarized = {
      dark = {
        base03 = "#002b36"; # background
        base02 = "#073642"; # background highlights
        base01 = "#586e75"; # comments / secondary content
        base00 = "#657b83"; # body text / default code / primary content
        base0 = "#839496"; # primary content
        base1 = "#93a1a1"; # optional emphasized content
        base2 = "#eee8d5"; # background highlights (light theme)
        base3 = "#fdf6e3"; # background (light theme)
        yellow = "#b58900";
        orange = "#cb4b16";
        red = "#dc322f";
        magenta = "#d33682";
        violet = "#6c71c4";
        blue = "#268bd2";
        cyan = "#2aa198";
        green = "#859900";

        # Convenience aliases
        bg = "#002b36"; # base03
        bg_alt = "#073642"; # base02
        fg = "#839496"; # base0
        fg_alt = "#657b83"; # base00
        comment = "#586e75"; # base01
        accent = "#268bd2"; # blue
        accent_dim = "#073642"; # base02
      };
    };
  };

  appThemes = {
    wezterm = {
      catppuccin = {
        macchiato = "catppuccin-macchiato";
      };
      rose-pine = {
        moon = "Rosé Pine (Gogh)";
      };
      gruvbox = {
        dark = "Gruvbox dark, hard (base16)";
      };
      solarized = {
        dark = "Solarized Dark Higher Contrast (Gogh)";
      };
    };

    neovim = {
      catppuccin = {
        plugin = "catppuccin/nvim";
        name = "catppuccin";
        setup = "catppuccin";
        colorscheme = "catppuccin";
      };
      rose-pine = {
        plugin = "cdmill/neomodern.nvim";
        name = "neomodern";
        setup = "neomodern";
        colorscheme = "roseprime";
      };
      gruvbox = {
        plugin = "ellisonleao/gruvbox.nvim";
        name = "gruvbox";
        setup = "gruvbox";
        colorscheme = "gruvbox";
      };
      solarized = {
        plugin = "craftzdog/solarized-osaka.nvim";
        name = "solarized-osaka";
        setup = "solarized-osaka";
        colorscheme = "solarized-osaka";
      };
    };

    delta = {
      catppuccin = {
        macchiato = "catppuccin-macchiato";
      };
      rose-pine = {
        moon = "rose-pine-moon";
      };
      gruvbox = {
        dark = "gruvbox-dark";
      };
      solarized = {
        dark = "solarized-dark";
      };
    };

    bat = {
      catppuccin = {
        macchiato = "Catppuccin-Macchiato";
      };
      rose-pine = {
        moon = "Rose-Pine-Moon";
      };
      gruvbox = {
        dark = "gruvbox-dark";
      };
      solarized = {
        dark = "Solarized (dark)";
      };
    };

    helix = {
      catppuccin = {
        macchiato = "catppuccin_macchiato";
      };
      rose-pine = {
        moon = "Rose-Pine-Moon";
      };
      gruvbox = {
        dark = "gruvbox-dark";
      };
      solarized = {
        dark = "Solarized (dark)";
      };
    };

    atuin = {
      catppuccin = {
        macchiato = "catppuccin-macchiato";
      };
      rose-pine = {
        moon = "rose_pine_moon";
      };
      gruvbox = {
        dark = "gruvbox_dark_hard";
      };
      solarized = {
        dark = "solarized_dark";
      };
    };

    vivid = {
      catppuccin = {
        macchiato = "catppuccin-macchiato";
      };
      rose-pine = {
        moon = "rose-pine-moon";
      };
      gruvbox = {
        dark = "gruvbox-dark";
      };
      solarized = {
        dark = "solarized-dark";
      };
    };

    nushell = {
      catppuccin = {
        macchiato = "catppuccin_macchiato.nu";
      };
      rose-pine = {
        moon = "rose_pine_moon.nu";
      };
      gruvbox = {
        dark = "gruvbox_dark.nu";
      };
      solarized = {
        dark = "solarized_dark.nu";
      };
    };

  };

  # Helper function to get current theme palette
  getThemePalette =
    colorscheme: variant:
    palettes.${colorscheme}.${variant} or (throw "Theme ${colorscheme}:${variant} not found");

  # Helper function to get app-specific theme name
  getAppTheme =
    app: colorscheme: variant:
    appThemes.${app}.${colorscheme}.${variant} or "${colorscheme}-${variant}";

  # Create unified color mappings based on palette
  getUnifiedColors =
    palette: with palette; {
      # Primary colors - these will always exist in all themes
      primary = accent;
      background = base;
      foreground = text;
      secondary = palette.surface1 or palette.surface or palette.overlay or palette.base;

      # Semantic colors with fallbacks
      success = green;
      warning = yellow;
      error = red;
      info = blue;

      # UI colors
      border = palette.surface2 or palette.surface or palette.overlay or palette.base;
      muted = palette.subtext1 or palette.muted or palette.subtle or palette.text;
      subtle = palette.subtext0 or palette.subtle or palette.muted or palette.text;
    };

  hexToAnsi = ansiCode: "38;5;${toString ansiCode}";

  ansiMappings = {
    catppuccin = {
      macchiato = {
        blue = "117";
        peach = "216";
        mauve = "183";
        teal = "152";
        green = "151";
        yellow = "223";
        pink = "211";
        surface1 = "238";
        surface2 = "240";
      };
    };
    rose-pine = {
      moon = {
        iris = "183"; # #c4a7e7 -> light magenta
        foam = "152"; # #9ccfd8 -> cyan
        pine = "117"; # #3e8fb0 -> blue
        love = "211"; # #eb6f92 -> light red
        gold = "216"; # #f6c177 -> orange
        rose = "216"; # #ea9a97 -> orange
        overlay = "238"; # #393552 -> dark gray
        surface = "240"; # #2a273f -> gray
      };
    };
    solarized = {
      dark = {
        blue = "33"; # #268bd2
        cyan = "37"; # #2aa198
        green = "64"; # #859900
        yellow = "136"; # #b58900
        orange = "166"; # #cb4b16
        red = "160"; # #dc322f
        magenta = "125"; # #d33682
        violet = "61"; # #6c71c4
        base02 = "240"; # #073642
        base01 = "244"; # #586e75
      };
    };
    gruvbox = {
      dark = {
        blue = "109"; # #83a598 -> blue
        orange = "208"; # #fe8019 -> orange
        purple = "175"; # #d3869b -> magenta
        aqua = "108"; # #8ec07c -> cyan
        green = "142"; # #b8bb26 -> green
        yellow = "214"; # #fabd2f -> yellow
        red = "167"; # #fb4934 -> red
        bg1 = "237"; # #3c3836 -> dark gray
        bg2 = "239"; # #504945 -> gray
      };
    };
  };

in
{
  inherit
    palettes
    appThemes
    getThemePalette
    getAppTheme
    getUnifiedColors
    hexToAnsi
    ansiMappings
    ;
}
