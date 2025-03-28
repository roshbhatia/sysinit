{ config, lib, pkgs, ... }:

{
  xdg.configFile."sketchybar/sketchybarrc" = {
    source = ./sketchybarrc;
  };
}