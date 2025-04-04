{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = ./wezterm.lua;
  };

  # Help script now consolidated into sysinit-help.sh
}