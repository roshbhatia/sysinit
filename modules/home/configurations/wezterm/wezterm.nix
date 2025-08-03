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

  # Create theme configuration using new modular system
  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency // (nvimOverride.transparency or { });
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };
in

{
  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";

  xdg.configFile."wezterm/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "wezterm" themeConfig
  );

}
