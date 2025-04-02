{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = ./wezterm.lua;
  };

  xdg.configFile."zsh/extras/bin/wezterm-help" = {
    source = ./wezterm-help.sh;
  };
}