{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  nvimOverride =
    if values.wezterm.nvim_transparency_override or null != null then
      { transparency = values.wezterm.nvim_transparency_override; }
    else
      { };

  themeConfig = themes.withThemeOverrides values "wezterm" nvimOverride;
in

{
  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";

  xdg.configFile."wezterm/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON {
    colorscheme = themeConfig.colorscheme;
    variant = themeConfig.variant;
    transparency = themeConfig.transparency;
    theme_name = themeConfig.appTheme;
    palette = themeConfig.palette;
    ansi = themes.ansiMappings.${themeConfig.colorscheme}.${themeConfig.variant} or { };
  };

}
