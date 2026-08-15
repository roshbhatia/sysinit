{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;
  launcherConfig = {
    wezterm = "${pkgs.wezterm}/bin/wezterm";
    sy = "/etc/profiles/per-user/${config.home.username}/bin/sy";
    fftabs = "${pkgs.sysinit-utils}/bin/firefox-tabs";
    bat = "${pkgs.bat}/bin/bat";
    # What a `!` command in the launcher is run by.
    shell = "${pkgs.zsh}/bin/zsh";
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
  home.file = {
    ".hammerspoon/init.lua".source = ./init.lua;
    ".hammerspoon/lua".source = ./lua;
    ".config/sysinit/launcher_config.json".text = builtins.toJSON launcherConfig;
    ".hammerspoon/Spoons/VimMode.spoon" = {
      source = pkgs.fetchFromGitHub {
        owner = "dbalatero";
        repo = "VimMode.spoon";
        rev = "dda997f79e240a2aebf1929ef7213a1e9db08e97";
        sha256 = "sha256-zpx2lh/QsmjP97CBsunYwJslFJOb0cr4ng8YemN5F0Y=";
      };
      recursive = true;
    };
  };
}
