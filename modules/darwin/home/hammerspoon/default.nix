{ pkgs, ... }:

let
  # The launcher's paths and commands. Nix owns them, because Hammerspoon runs with a
  # minimal PATH and a bare tool name is not found there.
  launcherConfig = {
    wezterm = "${pkgs.wezterm}/bin/wezterm";
    sy = "/etc/profiles/per-user/roshan/bin/sy";
    appDirs = [
      "/Applications"
      "/System/Applications"
      "/Applications/Utilities"
      "/System/Applications/Utilities"
      "/Users/roshan/Applications"
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
