{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "/Users/${config.user.username}/github/personal/roshbhatia/sysinit/modules/darwin/home/wezterm";
    force = true;
  };
}
