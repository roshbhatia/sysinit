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
  # Stylix handles wezterm colors and opacity automatically

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    # Minimal config for Lua — only what Stylix doesn't handle
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
