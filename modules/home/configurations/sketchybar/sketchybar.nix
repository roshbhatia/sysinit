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
  path = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar";
in

{
  xdg.configFile."sketchybar/sketchybarrc".source = "${path}/sketchybar.lua";

  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";

  xdg.configFile."sketchybar/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "sketchybar" themeConfig
  );
}
