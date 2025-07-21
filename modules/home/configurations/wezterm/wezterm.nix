{
  lib,
  overlay,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette overlay.theme.colorscheme overlay.theme.variant;
  appTheme = themes.getAppTheme "wezterm" overlay.theme.colorscheme overlay.theme.variant;
  
  themeConfig = {
    colorscheme = overlay.theme.colorscheme;
    variant = overlay.theme.variant;
    transparency = overlay.theme.transparency;
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
  
  # Generate theme configuration for lua to read
  xdg.configFile."wezterm/lua/sysinit/theme_config.lua".text = ''
    -- Auto-generated theme configuration
    local M = {}

    M.colorscheme = "${themeConfig.colorscheme}"
    M.variant = "${themeConfig.variant}"
    M.transparency = {
      enable = ${if themeConfig.transparency.enable then "true" else "false"},
      opacity = ${toString themeConfig.transparency.opacity}
    }
    
    M.theme_name = "${appTheme}"
    
    M.palette = {
      ${lib.concatStringsSep ",\n      " (lib.mapAttrsToList (name: value: "${name} = \"${value}\"") palette)}
    }

    return M
  '';
}
