{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/wezterm/wezterm.lua";
    force = true;
  };
}
