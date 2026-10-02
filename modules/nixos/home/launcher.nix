{
  config,
  lib,
  pkgs,
  ...
}:

let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;

  wezterm = "${pkgs.wezterm}/bin/wezterm";
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  jq = "${pkgs.jq}/bin/jq";
  fftabs = "${pkgs.sysinit-utils}/bin/firefox-tabs";

  sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";

  menuPrelude = builtins.readFile ./launcher/menu-prelude.lua;

  render =
    path: replacements:
    lib.replaceStrings (lib.attrNames replacements) (map (name: replacements.${name}) (
      lib.attrNames replacements
    )) (builtins.readFile path);

in
{
  home.packages = with pkgs; [
    walker
    wl-clipboard
    imagemagick
  ];

  services.elephant.enable = true;

  xdg.configFile = {

    "elephant/symbols.toml".text = ''
      history = true
      history_when_empty = false
      command = "wl-copy"
      locale = "en"
    '';

    "elephant/clipboard.toml".text = ''
      time_format = "relative"
    '';

    "elephant/desktopapplications.toml".text = ''
      history = true
    '';

    "elephant/menus/panes.lua".text = render ./launcher/panes.lua {
      "@jq@" = jq;
      "-- @menu-prelude@" = menuPrelude;
      "@wezterm@" = wezterm;
    };

    "elephant/menus/sessions.lua".text = render ./launcher/sessions.lua {
      "@jq@" = jq;
      "-- @menu-prelude@" = menuPrelude;
      "@sy@" = sy;
      "@wezterm@" = wezterm;
    };

    "elephant/menus/tabs.lua".text = render ./launcher/tabs.lua {
      "@firefox-tabs@" = fftabs;
      "@jq@" = jq;
      "-- @menu-prelude@" = menuPrelude;
    };

    "elephant/menus/windows.lua".text = render ./launcher/windows.lua {
      "@head@" = "${pkgs.coreutils}/bin/head";
      "@jq@" = jq;
      "@ls@" = "${pkgs.coreutils}/bin/ls";
      "-- @menu-prelude@" = menuPrelude;
      "@swaymsg@" = swaymsg;
    };

    "walker/config.toml".text = ''
      theme = "sysinit"
      close_when_open = true
      click_to_close = true
      selection_wrap = false

      [providers]
      default = [
        "desktopapplications",
        "menus:windows",
        "menus:panes",
        "menus:sessions",
        "menus:tabs",
        "calc",
      ]
      empty = [
        "desktopapplications",
        "menus:windows",
        "menus:panes",
        "menus:sessions",
      ]
      max_results = 50

      [placeholders]
      "default" = { input = "Search apps, windows, panes, tabs, : for emoji, ! to run", list = "No results" }
      "symbols" = { input = "Search emoji by name", list = "No emoji" }
      "runner" = { input = "Run a command", list = "No command" }
      "files" = { input = "Search files and folders by path", list = "No paths" }
      "clipboard" = { input = "Search the clipboard history", list = "Nothing held" }

      [[providers.prefixes]]
      prefix = ":"
      provider = "symbols"

      [[providers.prefixes]]
      prefix = "!"
      provider = "runner"

      [[providers.prefixes]]
      prefix = "/"
      provider = "files"

      [[providers.prefixes]]
      prefix = ","
      provider = "clipboard"

      [[providers.prefixes]]
      prefix = "="
      provider = "calc"

      [[providers.prefixes]]
      prefix = "@"
      provider = "websearch"

      [[providers.prefixes]]
      prefix = ";"
      provider = "providerlist"
    '';

    "walker/themes/sysinit/style.css".text = render ./launcher/style.css {
      "@accent@" = c.base0D;
      "@background-alt@" = c.base01;
      "@background-selection@" = c.base02;
      "@background@" = c.base00;
      "@error@" = c.base08;
      "@font@" = config.sysinit.theme.font.monospace;
      "@foreground-dim@" = c.base04;
      "@foreground-muted@" = c.base03;
      "@foreground@" = c.base05;
      "@warning@" = c.base0A;
    };
  };
}
