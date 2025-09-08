{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
    config = ''
      lua ~/.config/sketchybar/init.lua
    '';
  };

}
