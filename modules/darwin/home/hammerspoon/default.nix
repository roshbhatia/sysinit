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

    base16 = lib.listToAttrs (map (name: lib.nameValuePair name "#${c.${name}}") slots);
    inherit (config.sysinit.theme) transparency;
  };
  launcherConfig = {
    clipboard = true;
    stateDir = "${home}/.local/state/sysinit/launcher";
    recencyFile = "${home}/.local/state/sysinit/launcher_recency.json";
    emojiFile = "${home}/.local/state/sysinit/launcher_emoji.json";
    wezterm = "${pkgs.wezterm}/bin/wezterm";
    sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";
    fftabs = "${pkgs.firefox-tabs}/bin/firefox-tabs";
    firefoxProfileRoot = "${home}/Library/Application Support/Firefox/Profiles";
    bat = "${pkgs.bat}/bin/bat";

    emoji = "${emojiData}";

    shell = "${pkgs.nushell}/bin/nu";
    browser = "Firefox";
    searchURL = "https://www.google.com/search?q=%s";
    fzf = "${pkgs.fzf}/bin/fzf";
    fd = "${pkgs.fd}/bin/fd";
    timeout = "${pkgs.coreutils}/bin/timeout";
    fileRoots = [
      home
    ];

    fileDeadline = 15;

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
  imports = [ ./url-routing.nix ];

  options.sysinit.hammerspoon.appExcludes = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Application bundle names omitted from the Hammerspoon launcher";
  };

  config = {
    sysinit.hammerspoon.appExcludes = lib.mkBefore defaultAppExcludes;

    launchd.agents.hammerspoon = {
      enable = true;
      config = {
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "-W"
          "-a"
          "/Applications/Hammerspoon.app"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 5;
        LimitLoadToSessionType = "Aqua";
        ProcessType = "Interactive";
        StandardOutPath = "${home}/Library/Logs/hammerspoon-launcher.log";
        StandardErrorPath = "${home}/Library/Logs/hammerspoon-launcher.error.log";
      };
    };

    home.file = {
      ".hammerspoon/Spoons/CommandPalette.spoon".source = pkgs.command-palette;
      ".hammerspoon/init.lua".source = ./init.lua;
      ".hammerspoon/lua".source = ./lua;
      ".config/sysinit/launcher_config.json".source =
        pkgs.sysinit.writeJSON "hammerspoon-default.json" launcherConfig;
      ".config/sysinit/theme_config.json".source =
        pkgs.sysinit.writeJSON "hammerspoon-default.json" themeConfig;
    };
  };
}
