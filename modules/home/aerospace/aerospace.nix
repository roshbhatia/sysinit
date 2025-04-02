{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."zsh/extras/bin/aerospace-help" = {
    source = ./aerospace-help.sh;
  };

  xdg.configFile."aerospace/cycle-resize" = {
    source = ./cycle-resize.sh;
  };
}