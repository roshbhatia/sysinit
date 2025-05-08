{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/wezterm";
    force = true;
  };
}
