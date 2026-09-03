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
  # seshy is installed per-user rather than from a store path, the same way the
  # Hammerspoon launcher reaches it.
  sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";

  # TSV avoids elephant's inconsistently named JSON decoder global.
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

  # Menus are read from ~/.config/elephant/menus, and each provider reads its
  # own ~/.config/elephant/<provider>.toml, so there is nothing for the
  # top-level settings to carry.
  services.elephant.enable = true;

  xdg.configFile = {
    # The emoji picker. `history_when_empty = false` is the whole reason this
    # file exists: it ranks by what was picked before once something is typed,
    # and shows nothing on an empty query, so recents live in this sub-picker
    # and never reach the main list. `wl-copy` is the default command and is
    # named here because the copy is the point of the picker.
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

    # elephant ships a `windows` provider, but its only implementation is niri,
    # and on sway it returns an empty list rather than an error. This menu is
    # what makes Super+Tab work here.
    #
    # The socket is found rather than read from SWAYSOCK. elephant is started by
    # graphical-session.target, which wins the race against the
    # `dbus-update-activation-environment` sway runs from its own startup list:
    # measured on arrakis, `systemctl --user show-environment` has SWAYSOCK and
    # the running elephant process does not, so every window query came back
    # empty.
    "elephant/menus/windows.lua".text = render ./launcher/windows.lua {
      "@head@" = "${pkgs.coreutils}/bin/head";
      "@jq@" = jq;
      "@ls@" = "${pkgs.coreutils}/bin/ls";
      "-- @menu-prelude@" = menuPrelude;
      "@swaymsg@" = swaymsg;
    };

    # `:` is the emoji prefix and `!` runs a command, both to match what the
    # Hammerspoon launcher already does on the other host. That costs the two
    # defaults walker ships on those keys: clipboard moves to `,` and the todo
    # provider is not configured here.
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

    # Only style.css is written. walker reads a theme directory file by file and
    # falls back to the compiled-in default for anything absent, so the layout
    # and every item template stay upstream's.
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
