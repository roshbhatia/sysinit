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

    nord = {
      dark = {
        # Polar Night (darker backgrounds)
        nord0 = "#2e3440";
        nord1 = "#3b4252";
        nord2 = "#434c5e";
        nord3 = "#4c566a";

        # Snow Storm (lighter foregrounds)
        nord4 = "#d8dee9";
        nord5 = "#e5e9f0";
        nord6 = "#eceff4";

        # Frost (blues and teals)
        nord7 = "#8fbcbb";
        nord8 = "#88c0d0";
        nord9 = "#81a1c1";
        nord10 = "#5e81ac";

        # Aurora (accent colors)
        nord11 = "#bf616a"; # red
        nord12 = "#d08770"; # orange
        nord13 = "#ebcb8b"; # yellow
        nord14 = "#a3be8c"; # green
        nord15 = "#b48ead"; # purple

        # Convenience aliases
        base = "#2e3440"; # nord0
        bg = "#2e3440"; # nord0
        bg_alt = "#3b4252"; # nord1
        surface = "#434c5e"; # nord2
        surface_alt = "#4c566a"; # nord3
        text = "#eceff4"; # nord6
        fg = "#eceff4"; # nord6
        fg_alt = "#e5e9f0"; # nord5
        comment = "#4c566a"; # nord3
        blue = "#5e81ac"; # nord10
        cyan = "#88c0d0"; # nord8
        teal = "#8fbcbb"; # nord7
        green = "#a3be8c"; # nord14
        yellow = "#ebcb8b"; # nord13
        orange = "#d08770"; # nord12
        red = "#bf616a"; # nord11
        purple = "#b48ead"; # nord15
        accent = "#5e81ac"; # nord10 (blue)
        accent_dim = "#434c5e"; # nord2
      };
    };

    kanagawa = {
      wave = {
        # Kanagawa Wave (default dark theme)
        sumiInk0 = "#16161d";
        sumiInk1 = "#1f1f28";
        sumiInk2 = "#2a2a37";
        sumiInk3 = "#363646";
        sumiInk4 = "#54546d";

        oldWhite = "#c8c093";
        fujiWhite = "#dcd7ba";
        fujiGray = "#727169";

        waveBlue1 = "#223249";
        waveBlue2 = "#2d4f67";
        waveAqua1 = "#6a9589";
        waveAqua2 = "#7aa89f";

        winterGreen = "#2b3328";
        winterYellow = "#49443c";
        winterRed = "#43242b";
        winterBlue = "#252535";

        autumnGreen = "#76946a";
        autumnRed = "#c34043";
        autumnYellow = "#dca561";

        samuraiRed = "#e82424";
        roninYellow = "#ff9e3b";
        dragonBlue = "#658594";

        crystalBlue = "#7e9cd8";
        springViolet1 = "#938aa9";
        springViolet2 = "#9cabca";
        springBlue = "#7fb4ca";
        springGreen = "#98bb6c";
        boatYellow2 = "#c0a36e";
        carpYellow = "#e6c384";
        sakuraPink = "#d27e99";
        waveRed = "#e46876";
        peachRed = "#ff5d62";
        surimiOrange = "#ffa066";
        oniViolet = "#957fb8";

        # Convenience aliases
        base = "#1f1f28"; # sumiInk1
        bg = "#1f1f28"; # sumiInk1
        bg_alt = "#16161d"; # sumiInk0
        surface = "#2a2a37"; # sumiInk2
        surface_alt = "#363646"; # sumiInk3
        text = "#dcd7ba"; # fujiWhite
        fg = "#dcd7ba"; # fujiWhite
        fg_alt = "#c8c093"; # oldWhite
        comment = "#727169"; # fujiGray
        blue = "#7e9cd8"; # crystalBlue
        cyan = "#7fb4ca"; # springBlue
        teal = "#6a9589"; # waveAqua1
        green = "#98bb6c"; # springGreen
        yellow = "#e6c384"; # carpYellow
        orange = "#ffa066"; # surimiOrange
        red = "#c34043"; # autumnRed
        purple = "#957fb8"; # oniViolet
        accent = "#7e9cd8"; # crystalBlue
        accent_dim = "#2a2a37"; # sumiInk2
      };


      dragon = {
        # Kanagawa Dragon (darker variant)
        dragonBlack0 = "#0d0c0c";
        dragonBlack1 = "#12120f";
        dragonBlack2 = "#1d1c19";
        dragonBlack3 = "#181616";
        dragonBlack4 = "#282727";
        dragonBlack5 = "#393836";
        dragonBlack6 = "#625e5a";

        dragonWhite = "#c5c9c5";
        dragonGreen = "#87a987";
        dragonGreen2 = "#8a9a7b";
        dragonPink = "#a292a3";
        dragonOrange = "#b6927b";
        dragonOrange2 = "#b98d7b";
        dragonGray = "#a6a69c";
        dragonGray2 = "#9e9b93";
        dragonGray3 = "#7a8382";
        dragonBlue = "#8ba4b0";
        dragonBlue2 = "#8ea4a2";
        dragonViolet = "#8992a7";
        dragonRed = "#c4746e";
        dragonAqua = "#8ea4a2";
        dragonAsh = "#737c73";
        dragonTeal = "#949fb5";
        dragonYellow = "#c4b28a";

        # Convenience aliases
        base = "#181616"; # dragonBlack3
        bg = "#181616"; # dragonBlack3
        bg_alt = "#12120f"; # dragonBlack1
        surface = "#1d1c19"; # dragonBlack2
        surface_alt = "#282727"; # dragonBlack4
        text = "#c5c9c5"; # dragonWhite
        fg = "#c5c9c5"; # dragonWhite
        fg_alt = "#a6a69c"; # dragonGray
        comment = "#7a8382"; # dragonGray3
        blue = "#8ba4b0"; # dragonBlue
        cyan = "#8ea4a2"; # dragonAqua
        teal = "#949fb5"; # dragonTeal
        green = "#87a987"; # dragonGreen
        yellow = "#c4b28a"; # dragonYellow
        orange = "#b6927b"; # dragonOrange
        red = "#c4746e"; # dragonRed
        purple = "#8992a7"; # dragonViolet
        accent = "#8ba4b0"; # dragonBlue
        accent_dim = "#1d1c19"; # dragonBlack2
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
      nord = {
        dark = "Nord (base16)";
      };
      kanagawa = {
        wave = "Kanagawa (Gogh)";
        dragon = "Kanagawa Dragon (Gogh)";
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
      nord = {
        plugin = "EdenEast/nightfox.nvim";
        name = "nightfox";
        setup = "nightfox";
        colorscheme = "nordfox";
      };
      kanagawa = {
        wave = {
          plugin = "rebelot/kanagawa.nvim";
          name = "kanagawa";
          setup = "kanagawa";
          colorscheme = "kanagawa-wave";
        };
        dragon = {
          plugin = "rebelot/kanagawa.nvim";
          name = "kanagawa";
          setup = "kanagawa";
          colorscheme = "kanagawa-dragon";
        };
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
      nord = {
        dark = "nord-dark";
      };
      kanagawa = {
        wave = "kanagawa-dark";
        dragon = "kanagawa-dragon";
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
      nord = {
        dark = "Nord";
      };
      kanagawa = {
        wave = "Kanagawa";
        dragon = "Kanagawa Dragon";
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
      nord = {
        dark = "nord";
      };
      kanagawa = {
        wave = "kanagawa";
        dragon = "kanagawa";
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
      nord = {
        dark = "nord";
      };
      kanagawa = {
        wave = "kanagawa";
        dragon = "kanagawa";
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
      nord = {
        dark = "nord";
      };
      kanagawa = {
        wave = "kanagawa";
        dragon = "kanagawa";
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
      nord = {
        dark = "nord_dark.nu";
      };
      kanagawa = {
        wave = "kanagawa.nu";
        dragon = "kanagawa.nu";
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
      background = palette.base or palette.bg0 or palette.base03;
      foreground = palette.text or palette.fg1 or palette.base0;
      secondary = palette.surface1 or palette.surface or palette.overlay or palette.bg1 or palette.base02;

      # Semantic colors with fallbacks
      success = green;
      warning = yellow;
      error = red;
      info = blue;

      # UI colors
      border =
        palette.surface2 or palette.surface or palette.overlay or palette.bg2 or palette.base02
          or (palette.base or palette.bg0 or palette.base03);
      muted =
        palette.subtext1 or palette.muted or palette.subtle or palette.fg3 or palette.base01
          or (palette.text or palette.fg1 or palette.base0);
      subtle =
        palette.subtext0 or palette.subtle or palette.muted or palette.fg4 or palette.base00
          or (palette.text or palette.fg1 or palette.base0);
    };

  # Helper function to merge theme config with overrides
  mergeThemeConfig =
    base: overrides:
    let
      # Helper to deeply merge transparency settings
      mergeTransparency =
        base: override:
        if override ? transparency then
          base
          // {
            transparency = (base.transparency or { }) // override.transparency;
          }
        else
          base;
    in
    if overrides == { } then base else mergeTransparency base overrides;

  # Get theme configuration for a specific app with optional overrides
  getThemeForApp =
    app: colorscheme: variant: themeConfig: overrides:
    let
      palette = getThemePalette colorscheme variant;
      appTheme =
        if app == "wezterm" then
          getAppTheme app colorscheme variant
        else
          appThemes.${app}.${colorscheme} or { };

      # Default transparency settings
      defaultTransparency = {
        enable = false;
        opacity = 0.85; # Default when transparency is enabled
      };

      # Merge theme config with defaults and overrides
      finalConfig = mergeThemeConfig {
        colorscheme = colorscheme;
        variant = variant;
        transparency = themeConfig.transparency or defaultTransparency;
        appTheme = appTheme;
        palette = palette;
      } overrides;
    in
    finalConfig;

  # Simplified interface for getting theme with overrides
  withThemeOverrides =
    values: app: overrides:
    getThemeForApp app values.theme.colorscheme values.theme.variant values.theme overrides;

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
    nord = {
      dark = {
        red = "167"; # #bf616a -> red
        orange = "173"; # #d08770 -> orange
        yellow = "222"; # #ebcb8b -> yellow
        green = "150"; # #a3be8c -> green
        cyan = "152"; # #88c0d0 -> cyan
        blue = "67"; # #5e81ac -> blue
        purple = "139"; # #b48ead -> purple
        nord0 = "236"; # #2e3440 -> dark gray
        nord1 = "237"; # #3b4252 -> gray
        nord2 = "240"; # #434c5e -> gray
        nord3 = "241"; # #4c566a -> gray
      };
    };
    kanagawa = {
      wave = {
        red = "167"; # #c34043 -> red
        orange = "215"; # #ffa066 -> orange
        yellow = "179"; # #e6c384 -> yellow
        green = "108"; # #98bb6c -> green
        cyan = "109"; # #7fb4ca -> cyan
        blue = "67"; # #7e9cd8 -> blue
        purple = "103"; # #957fb8 -> purple
        sumiInk0 = "233"; # #16161d -> very dark
        sumiInk1 = "234"; # #1f1f28 -> dark
        sumiInk2 = "236"; # #2a2a37 -> dark gray
      };
      dragon = {
        red = "167"; # #c4746e -> red
        orange = "179"; # #b6927b -> orange
        yellow = "179"; # #c4b28a -> yellow
        green = "108"; # #87a987 -> green
        cyan = "109"; # #8ea4a2 -> cyan
        blue = "109"; # #8ba4b0 -> blue
        purple = "103"; # #8992a7 -> purple
        dragonBlack0 = "232"; # #0d0c0c -> very dark
        dragonBlack1 = "233"; # #12120f -> dark
        dragonBlack2 = "235"; # #1d1c19 -> dark gray
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
    getThemeForApp
    withThemeOverrides
    mergeThemeConfig
    hexToAnsi
    ansiMappings
    ;
}
