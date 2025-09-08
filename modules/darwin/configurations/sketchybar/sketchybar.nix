{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency or { };
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };
in

{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
    config = ''
      lua ~/.config/sketchybar/init.lua
    '';
  };

  xdg.configFile."sketchybar/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/configurations/sketchybar/init.lua";

  xdg.configFile."sketchybar/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/configurations/sketchybar/lua";

  xdg.configFile."sketchybar/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "sketchybar" themeConfig
  );
}
