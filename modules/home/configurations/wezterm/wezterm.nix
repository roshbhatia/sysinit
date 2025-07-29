{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  appTheme = themes.getAppTheme "wezterm" values.theme.colorscheme values.theme.variant;

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency;
    appTheme = appTheme;
    palette = palette;
  };
in

{
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua" = {
    source = ./lua;
    recursive = true;
  };

  xdg.configFile."wezterm/lua/sysinit/theme_config.lua".text = ''
    local M = {}

    M.colorscheme = "${themeConfig.colorscheme}"
    M.variant = "${themeConfig.variant}"
    M.transparency = {
      enable = ${if themeConfig.transparency.enable then "true" else "false"},
      opacity = ${toString themeConfig.transparency.opacity}
    }

    M.theme_name = "${appTheme}"

    M.palette = {
      ${lib.concatStringsSep ",\n      " (
        lib.mapAttrsToList (name: value: "${name} = \"${value}\"") palette
      )}
    }

    return M
  '';
}
