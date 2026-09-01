{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.home.homeDirectory;
  defaultAppExcludes = [
    "Apps.app"
    "Calendar.app"
    "Chess.app"
    "Clock.app"
    "Freeform.app"
    "GarageBand.app"
    "Games.app"
    "Home.app"
    "Image Capture.app"
    "Journal.app"
    "Keynote.app"
    "Mail.app"
    "Maps.app"
    "News.app"
    "Numbers.app"
    "Pages.app"
    "Photos.app"
    "Reminders.app"
    "Siri.app"
    "Stickies.app"
    "Stocks.app"
    "TV.app"
    "Tips.app"
    "Weather.app"
  ];
  emojiData = import ./emoji.nix { inherit pkgs; };
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  c = themeLib.colorsOf config;
  slots = [
    "base00"
    "base01"
    "base02"
    "base03"
    "base04"
    "base05"
    "base06"
    "base07"
    "base08"
    "base09"
    "base0A"
    "base0B"
    "base0C"
    "base0D"
    "base0E"
    "base0F"
  ];
  themeConfig = {
    # The eight roles `pkg/theme` reads. Kept as roles rather than slots because
    # the window switcher and the workspace overlay ask for a background or an
    # accent, not for base01.
    palette = {
      bg_primary = "#${c.base00}";
      bg_secondary = "#${c.base01}";
      bg_tertiary = "#${c.base02}";
      bg_overlay = "#${c.base03}";
      fg_primary = "#${c.base05}";
      fg_muted = "#${c.base04}";
      primary = "#${c.base0D}";
      accent = "#${c.base0E}";
    };
    # The launcher page composes its own rgba() per CSS variable, so it gets the
    # whole scheme rather than the eight roles above.
    base16 = lib.listToAttrs (map (name: lib.nameValuePair name "#${c.${name}}") slots);
    inherit (config.sysinit.theme) transparency;
  };
  launcherConfig = {
    wezterm = "${pkgs.wezterm}/bin/wezterm";
    sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";
    fftabs = "${pkgs.sysinit-utils}/bin/firefox-tabs";
    firefoxProfileRoot = "${home}/Library/Application Support/Firefox/Profiles";
    bat = "${pkgs.bat}/bin/bat";
    # Read by the launcher's `:` mode. Built from the same CLDR annotations
    # arrakis reads through elephant, so a shortcode resolves the same on both.
    emoji = "${emojiData}";
    # What a `!` command in the launcher is run by.
    shell = "${pkgs.zsh}/bin/zsh";
    browser = "Firefox";
    searchURL = "https://www.google.com/search?q=%s";
    fzf = "${pkgs.fzf}/bin/fzf";
    fd = "${pkgs.fd}/bin/fd";
    timeout = "${pkgs.coreutils}/bin/timeout";
    fileRoots = [
      home
    ];
    # ~/Desktop, ~/Documents and ~/Downloads are TCC-protected. Hammerspoon holds
    # no grant for them, and tccd will not prompt for the walk, so readdir blocks
    # there until something kills it. Without this bound the walk never finishes
    # and the index it was writing is never published. Grant Hammerspoon Full
    # Disk Access and the walk finishes in about 4 seconds instead.
    fileDeadline = 15;
    # The walk is bounded by what it skips rather than by a depth, because real
    # source sits 14 levels below home and a depth that reaches it is no cheaper
    # than no depth at all. These trees hold 530k of the 620k paths under home,
    # and none of them is a path anybody searches for by name.
    fileExcludes = [
      ".cache"
      ".cargo"
      ".direnv"
      ".git"
      ".gradle"
      ".local"
      ".next"
      ".npm"
      ".ollama"
      ".pytest_cache"
      ".rustup"
      ".terraform"
      ".venv"
      "Library"
      "__pycache__"
      "build"
      "dist"
      "go"
      "node_modules"
      "target"
      "venv"
    ];
    fileCap = 150000;
    appDirs = [
      "/Applications"
      "/System/Applications"
      "/Applications/Utilities"
      "/System/Applications/Utilities"
      "${home}/Applications"
      "/Applications/Nix Apps"
      "${home}/Applications/Home Manager Apps"
    ];
    appExcludes = config.sysinit.hammerspoon.appExcludes;
    commands = [
      {
        label = "Lock screen";
        about = "command";
        run = "pmset displaysleepnow";
      }
      {
        label = "Reload Hammerspoon";
        about = "command";
        run = "/opt/homebrew/bin/hs -c 'hs.reload()'";
      }
      {
        label = "Sleep";
        about = "command";
        run = "pmset sleepnow";
      }
    ];
  };
in
{
  options.sysinit.hammerspoon.appExcludes = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Application bundle names omitted from the Hammerspoon launcher";
  };

  config = {
    sysinit.hammerspoon.appExcludes = lib.mkBefore defaultAppExcludes;

    home.file = {
      ".hammerspoon/init.lua".source = ./init.lua;
      ".hammerspoon/lua".source = ./lua;
      ".config/sysinit/launcher_config.json".text = builtins.toJSON launcherConfig;
      ".config/sysinit/theme_config.json".text = builtins.toJSON themeConfig;
    };
  };
}
