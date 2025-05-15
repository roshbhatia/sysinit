{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua" = {
    source = ./lua;
    recursive = true;
  };
}
