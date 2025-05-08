{ config, lib, pkgs, ... }:

{
  xdg.configFile."oh-my-posh/themes" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/omp";
    force = true;
  };
}
