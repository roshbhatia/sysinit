{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency;
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in

{
  xdg.configFile."wezterm/wezterm.lua".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";

  xdg.configFile."wezterm/lua".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

  xdg.configFile."wezterm/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "wezterm" themeConfig
  );

  xdg.configFile."wezterm/core_config.json".text = builtins.toJSON {
    wezterm_entrypoint = values.wezterm.shell;
  };
}
