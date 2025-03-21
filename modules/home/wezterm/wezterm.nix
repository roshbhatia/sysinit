{ config, lib, pkgs, ... }:

{
  # Wezterm config is managed through homebrew + xdg.configFile
  xdg.configFile."wezterm/wezterm.lua" = {
    source = ./wezterm.lua;
  };
}