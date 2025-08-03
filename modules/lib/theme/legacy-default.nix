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
        base03 = "#002b36";
        base02 = "#073642";
        base01 = "#586e75";
        base00 = "#657b83";
        base0 = "#839496";
        base1 = "#93a1a1";
        base2 = "#eee8d5";
        base3 = "#fdf6e3";
        yellow = "#b58900";
        orange = "#cb4b16";
        red = "#dc322f";
        magenta = "#d33682";
        violet = "#6c71c4";
        blue = "#268bd2";
        cyan = "#2aa198";
        green = "#859900";

        bg = "#002b36";
        bg_alt = "#073642";
        fg = "#839496";
        fg_alt = "#657b83";
        comment = "#586e75";
        accent = "#268bd2";
        accent_dim = "#073642";
      };
    };

    nord = {
      dark = {

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

        base = "#2e3440";
        bg = "#2e3440";
        bg_alt = "#3b4252";
        surface = "#434c5e";
        surface_alt = "#4c566a";
        text = "#eceff4";
        fg = "#eceff4";
        fg_alt = "#e5e9f0";
        comment = "#4c566a";
        blue = "#5e81ac";
        cyan = "#88c0d0";
        teal = "#8fbcbb";
        green = "#a3be8c";
        yellow = "#ebcb8b";
        orange = "#d08770";
        red = "#bf616a";
        purple = "#b48ead";
        accent = "#5e81ac";
        accent_dim = "#434c5e";
      };
    };

    kanagawa = {
      wave = {

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

        base = "#1f1f28";
        bg = "#1f1f28";
        bg_alt = "#16161d";
        surface = "#2a2a37";
        surface_alt = "#363646";
        text = "#dcd7ba";
        fg = "#dcd7ba";
        fg_alt = "#c8c093";
        comment = "#727169";
        blue = "#7e9cd8";
        cyan = "#7fb4ca";
        teal = "#6a9589";
        green = "#98bb6c";
        yellow = "#e6c384";
        orange = "#ffa066";
        red = "#c34043";
        purple = "#957fb8";
        accent = "#7e9cd8";
        accent_dim = "#2a2a37";
      };

      dragon = {

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

        base = "#181616";
        bg = "#181616";
        bg_alt = "#12120f";
        surface = "#1d1c19";
        surface_alt = "#282727";
        text = "#c5c9c5";
        fg = "#c5c9c5";
        fg_alt = "#a6a69c";
        comment = "#7a8382";
        blue = "#8ba4b0";
        cyan = "#8ea4a2";
        teal = "#949fb5";
        green = "#87a987";
        yellow = "#c4b28a";
        orange = "#b6927b";
        red = "#c4746e";
        purple = "#8992a7";
        accent = "#8ba4b0";
        accent_dim = "#1d1c19";
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
        wave = "kanagawa-wave";
        dragon = "kanagawa-dragon";
      };
    };

    bat = {
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
        wave = "kanagawa-wave";
        dragon = "kanagawa-dragon";
      };
    };

    helix = {
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
        wave = "kanagawa-wave";
        dragon = "kanagawa-dragon";
      };
    };

    atuin = {
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
        wave = "kanagawa-wave";
        dragon = "kanagawa-dragon";
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
        wave = "kanagawa-wave";
        dragon = "kanagawa-dragon";
      };
    };

    nushell = {
      catppuccin = {
        macchiato = "catppuccin-macchiato.nu";
      };
      rose-pine = {
        moon = "rose-pine-moon.nu";
      };
      gruvbox = {
        dark = "gruvbox-dark.nu";
      };
      solarized = {
        dark = "solarized-dark.nu";
      };
      nord = {
        dark = "nord-dark.nu";
      };
      kanagawa = {
        wave = "kanagawa-wave.nu";
        dragon = "kanagawa-dragon.nu";
      };
    };

  };

  getThemePalette =
    colorscheme: variant:
    getSafePalette (
      palettes.${colorscheme}.${variant} or (throw "Theme ${colorscheme}:${variant} not found")
    );

  getAppTheme =
    app: colorscheme: variant:
    appThemes.${app}.${colorscheme}.${variant} or "${colorscheme}-${variant}";

  getSafePalette =
    palette:
    let

      safeBase = {

        accent = palette.accent or palette.blue or "#0080ff";
        accent_dim = palette.accent_dim or palette.surface or palette.bg1 or "#333333";

        base = palette.base or palette.bg or palette.bg0 or palette.base03 or "#000000";
        bg = palette.bg or palette.base or palette.bg0 or palette.base03 or "#000000";
        bg_alt = palette.bg_alt or palette.mantle or palette.bg1 or palette.base02 or "#111111";

        text = palette.text or palette.fg or palette.fg1 or palette.base0 or "#ffffff";
        fg = palette.fg or palette.text or palette.fg1 or palette.base0 or "#ffffff";
        fg_alt = palette.fg_alt or palette.subtext1 or palette.fg2 or palette.base00 or "#cccccc";

        surface = palette.surface or palette.surface0 or palette.bg1 or palette.base02 or "#222222";
        surface_alt = palette.surface_alt or palette.surface1 or palette.bg2 or palette.base01 or "#333333";
        overlay = palette.overlay or palette.overlay0 or palette.surface or palette.bg2 or "#444444";

        comment = palette.comment or palette.fg_alt or palette.fg3 or palette.base01 or "#888888";
        muted = palette.muted or palette.subtext1 or palette.fg3 or palette.base01 or "#888888";
        subtle = palette.subtle or palette.subtext0 or palette.fg4 or palette.base00 or "#aaaaaa";

        red = palette.red or palette.love or palette.maroon or "#ff0000";
        green = palette.green or palette.pine or "#00ff00";
        yellow = palette.yellow or palette.gold or "#ffff00";
        blue = palette.blue or palette.sapphire or palette.cyan or "#0000ff";
        purple = palette.purple or palette.mauve or palette.iris or "#800080";
        orange = palette.orange or palette.peach or "#ff8000";
        cyan = palette.cyan or palette.teal or palette.foam or "#00ffff";
        teal = palette.teal or palette.cyan or "#008080";
      };

      themeSafeColors = {

        surface0 = palette.surface0 or safeBase.surface;
        surface1 = palette.surface1 or safeBase.surface_alt;
        surface2 = palette.surface2 or safeBase.overlay;
        overlay0 = palette.overlay0 or safeBase.overlay;
        overlay1 = palette.overlay1 or safeBase.muted;
        overlay2 = palette.overlay2 or safeBase.subtle;
        subtext0 = palette.subtext0 or safeBase.subtle;
        subtext1 = palette.subtext1 or safeBase.muted;
        mantle = palette.mantle or safeBase.bg_alt;
        crust = palette.crust or safeBase.bg_alt;
        rosewater = palette.rosewater or safeBase.text;
        flamingo = palette.flamingo or safeBase.orange;
        pink = palette.pink or safeBase.purple;
        mauve = palette.mauve or safeBase.purple;
        maroon = palette.maroon or safeBase.red;
        peach = palette.peach or safeBase.orange;
        sky = palette.sky or safeBase.cyan;
        sapphire = palette.sapphire or safeBase.blue;
        lavender = palette.lavender or safeBase.purple;

        base03 = palette.base03 or safeBase.base;
        base02 = palette.base02 or safeBase.bg_alt;
        base01 = palette.base01 or safeBase.comment;
        base00 = palette.base00 or safeBase.fg_alt;
        base0 = palette.base0 or safeBase.text;
        base1 = palette.base1 or safeBase.text;
        base2 = palette.base2 or safeBase.text;
        base3 = palette.base3 or safeBase.text;
        violet = palette.violet or safeBase.purple;
        magenta = palette.magenta or safeBase.purple;

        bg0_h = palette.bg0_h or safeBase.base;
        bg0 = palette.bg0 or safeBase.base;
        bg0_s = palette.bg0_s or safeBase.bg_alt;
        bg1 = palette.bg1 or safeBase.surface;
        bg2 = palette.bg2 or safeBase.surface_alt;
        bg3 = palette.bg3 or safeBase.overlay;
        bg4 = palette.bg4 or safeBase.comment;
        fg0 = palette.fg0 or safeBase.text;
        fg1 = palette.fg1 or safeBase.text;
        fg2 = palette.fg2 or safeBase.fg_alt;
        fg3 = palette.fg3 or safeBase.muted;
        fg4 = palette.fg4 or safeBase.subtle;
        gray = palette.gray or safeBase.comment;
        aqua = palette.aqua or safeBase.cyan;
        neutral_red = palette.neutral_red or safeBase.red;
        neutral_green = palette.neutral_green or safeBase.green;
        neutral_yellow = palette.neutral_yellow or safeBase.yellow;
        neutral_blue = palette.neutral_blue or safeBase.blue;
        neutral_purple = palette.neutral_purple or safeBase.purple;
        neutral_aqua = palette.neutral_aqua or safeBase.cyan;

        nord0 = palette.nord0 or safeBase.base;
        nord1 = palette.nord1 or safeBase.bg_alt;
        nord2 = palette.nord2 or safeBase.surface;
        nord3 = palette.nord3 or safeBase.surface_alt;
        nord4 = palette.nord4 or safeBase.fg_alt;
        nord5 = palette.nord5 or safeBase.fg_alt;
        nord6 = palette.nord6 or safeBase.text;
        nord7 = palette.nord7 or safeBase.teal;
        nord8 = palette.nord8 or safeBase.cyan;
        nord9 = palette.nord9 or safeBase.blue;
        nord10 = palette.nord10 or safeBase.blue;
        nord11 = palette.nord11 or safeBase.red;
        nord12 = palette.nord12 or safeBase.orange;
        nord13 = palette.nord13 or safeBase.yellow;
        nord14 = palette.nord14 or safeBase.green;
        nord15 = palette.nord15 or safeBase.purple;

        love = palette.love or safeBase.red;
        gold = palette.gold or safeBase.yellow;
        rose = palette.rose or safeBase.orange;
        pine = palette.pine or safeBase.green;
        foam = palette.foam or safeBase.cyan;
        iris = palette.iris or safeBase.purple;
        highlight_low = palette.highlight_low or safeBase.surface;
        highlight_med = palette.highlight_med or safeBase.surface_alt;
        highlight_high = palette.highlight_high or safeBase.overlay;

        sumiInk0 = palette.sumiInk0 or safeBase.bg_alt;
        sumiInk1 = palette.sumiInk1 or safeBase.base;
        sumiInk2 = palette.sumiInk2 or safeBase.surface;
        sumiInk3 = palette.sumiInk3 or safeBase.surface_alt;
        sumiInk4 = palette.sumiInk4 or safeBase.overlay;
        oldWhite = palette.oldWhite or safeBase.fg_alt;
        fujiWhite = palette.fujiWhite or safeBase.text;
        fujiGray = palette.fujiGray or safeBase.comment;
        crystalBlue = palette.crystalBlue or safeBase.blue;
        springBlue = palette.springBlue or safeBase.cyan;
        springGreen = palette.springGreen or safeBase.green;
        carpYellow = palette.carpYellow or safeBase.yellow;
        surimiOrange = palette.surimiOrange or safeBase.orange;
        oniViolet = palette.oniViolet or safeBase.purple;
        autumnGreen = palette.autumnGreen or safeBase.green;
        autumnRed = palette.autumnRed or safeBase.red;
        autumnYellow = palette.autumnYellow or safeBase.yellow;
        dragonBlack0 = palette.dragonBlack0 or safeBase.bg_alt;
        dragonBlack1 = palette.dragonBlack1 or safeBase.bg_alt;
        dragonBlack2 = palette.dragonBlack2 or safeBase.surface;
        dragonBlack3 = palette.dragonBlack3 or safeBase.base;
        dragonWhite = palette.dragonWhite or safeBase.text;
        dragonGreen = palette.dragonGreen or safeBase.green;
        dragonBlue = palette.dragonBlue or safeBase.blue;
        dragonViolet = palette.dragonViolet or safeBase.purple;
        dragonRed = palette.dragonRed or safeBase.red;
        dragonAqua = palette.dragonAqua or safeBase.cyan;
        dragonGray3 = palette.dragonGray3 or safeBase.comment;
        dragonYellow = palette.dragonYellow or safeBase.yellow;
        dragonOrange = palette.dragonOrange or safeBase.orange;
      };

    in
    safeBase // themeSafeColors;

  getUnifiedColors =
    palette:
    let
      safePalette = getSafePalette palette;
    in
    with safePalette;
    {

      primary = accent;
      background = base;
      foreground = text;
      secondary = surface;

      success = green;
      warning = yellow;
      error = red;
      info = blue;

      border = surface_alt;
      muted = muted;
      subtle = subtle;
    };

  mergeThemeConfig =
    base: overrides:
    let

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

  getThemeForApp =
    app: colorscheme: variant: themeConfig: overrides:
    let
      palette = getThemePalette colorscheme variant;
      appTheme =
        if app == "wezterm" then
          getAppTheme app colorscheme variant
        else
          appThemes.${app}.${colorscheme} or { };

      defaultTransparency = {
        enable = false;
        opacity = 0.85;
      };

      finalConfig = mergeThemeConfig {
        colorscheme = colorscheme;
        variant = variant;
        transparency = themeConfig.transparency or defaultTransparency;
        appTheme = appTheme;
        palette = palette;
      } overrides;
    in
    finalConfig;

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
        iris = "183";
        foam = "152";
        pine = "117";
        love = "211";
        gold = "216";
        rose = "216";
        overlay = "238";
        surface = "240";
      };
    };
    solarized = {
      dark = {
        blue = "33";
        cyan = "37";
        green = "64";
        yellow = "136";
        orange = "166";
        red = "160";
        magenta = "125";
        violet = "61";
        base02 = "240";
        base01 = "244";
      };
    };
    gruvbox = {
      dark = {
        blue = "109";
        orange = "208";
        purple = "175";
        aqua = "108";
        green = "142";
        yellow = "214";
        red = "167";
        bg1 = "237";
        bg2 = "239";
      };
    };
    nord = {
      dark = {
        red = "167";
        orange = "173";
        yellow = "222";
        green = "150";
        cyan = "152";
        blue = "67";
        purple = "139";
        nord0 = "236";
        nord1 = "237";
        nord2 = "240";
        nord3 = "241";
      };
    };
    kanagawa = {
      wave = {
        red = "167";
        orange = "215";
        yellow = "179";
        green = "108";
        cyan = "109";
        blue = "67";
        purple = "103";
        sumiInk0 = "233";
        sumiInk1 = "234";
        sumiInk2 = "236";
      };
      dragon = {
        red = "167";
        orange = "179";
        yellow = "179";
        green = "108";
        cyan = "109";
        blue = "109";
        purple = "103";
        dragonBlack0 = "232";
        dragonBlack1 = "233";
        dragonBlack2 = "235";
      };
    };
  };

in
{
  inherit
    palettes
    appThemes
    getSafePalette
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
