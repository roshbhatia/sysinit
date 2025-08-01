{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  paths = import ../../../lib/paths { inherit config lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  appTheme = themes.getAppTheme "wezterm" values.theme.colorscheme values.theme.variant;

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency;
    appTheme = appTheme;
    palette = palette;
  };

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
    transparency = {
      enable = themeConfig.transparency.enable;
      opacity = themeConfig.transparency.opacity;
    };
    theme_name = appTheme;
    palette = palette;
  };

  xdg.configFile."wezterm/lua/sysinit/paths_config.lua".text = ''
    local M = {}

    M.system_paths = {
      ${lib.concatStringsSep ",\n      " (map (path: "\"${path}\"") pathsArray)}
    }

    return M
  '';
}

