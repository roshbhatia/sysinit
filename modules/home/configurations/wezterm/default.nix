{
  config,
  lib,
  values,
  utils,
  ...
}:
with lib;
let
  inherit (utils.theme) generateAppJSON;

  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  config = {
    xdg.configFile."wezterm/wezterm.lua".source =
      mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";

    xdg.configFile."wezterm/lua".source =
      mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

    xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
      generateAppJSON "wezterm" themeConfig
    );

    xdg.configFile."wezterm/colors".source = ./colors;
  };
}
