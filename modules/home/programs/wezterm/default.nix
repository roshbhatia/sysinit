{
  config,
  lib,
  ...
}:

let
  paths = import ../../../lib/paths.nix { inherit lib; };
  themeConfig = config.sysinit.theme;
in
{
  # Stylix injects colors before our extraConfig runs.
  # We dofile() our custom wezterm.lua which sets up all modules.

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    extraConfig = ''
      local home_dir = os.getenv("HOME") or (os.getenv("USER") and "/Users/" .. os.getenv("USER"))
      return dofile(home_dir .. "/.config/wezterm/sysinit.lua")
    '';
  };

  xdg.configFile = {
    "wezterm/sysinit.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = builtins.toJSON {
      font = {
        monospace = themeConfig.font.monospace;
        symbols = themeConfig.font.symbols;
      };
      transparency = {
        opacity = themeConfig.transparency.opacity;
        blur = themeConfig.transparency.blur;
      };
    };
    "wezterm/env.json".text = builtins.toJSON {
      PATH = paths.getPathString config.home.username config.home.homeDirectory;
    };
  };
}
