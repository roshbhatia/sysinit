{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/sysinit" = {
    source = ./sysinit;
    recursive = true;
  };
}
