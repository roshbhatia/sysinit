{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."zsh/extras/bin/aerospace-help.sh" = {
    source = ./aerospace-help.sh;
  };
}