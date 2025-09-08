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

}
