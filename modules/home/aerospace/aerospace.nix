{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."aerospace/aerospace-help" = {
    source = ./aerospace-help.sh;
  };

  xdg.configFile."aerospace/smart-resize" = {
    source = ./smart-resize.sh;
  };

  xdg.configFile."aerospace/update-display-cache" = {
    source = ./update-display-cache.sh;
  };
}