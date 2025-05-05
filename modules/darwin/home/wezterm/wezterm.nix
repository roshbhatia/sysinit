{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./wezterm.lua;
    force = true;
  };
}
