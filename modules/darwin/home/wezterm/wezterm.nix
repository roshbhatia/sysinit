{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = ./wezterm.lua;
  };
}