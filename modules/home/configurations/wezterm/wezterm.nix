{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  paths = import ../../../lib/paths { inherit config lib; };

  nvimOverride =
    if values.wezterm.nvim_transparency_override or null != null then
      { transparency = values.wezterm.nvim_transparency_override; }
    else
      { };

  themeConfig = themes.withThemeOverrides values "wezterm" nvimOverride;
  pathsArray = paths.getPathArray config.home.username config.home.homeDirectory;
in

{
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua" = {
    source = ./lua;
    recursive = true;
  };

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON {
    colorscheme = themeConfig.colorscheme;
    variant = themeConfig.variant;
    transparency = themeConfig.transparency;
    theme_name = themeConfig.appTheme;
    palette = themeConfig.palette;
  };

  xdg.configFile."wezterm/lua/sysinit/paths_config.lua".text = ''
    local M = {}

    M.system_paths = {
      ${lib.concatStringsSep ",\n      " (map (path: "\"${path}\"") pathsArray)}
    }

    return M
  '';
}
