{ config, lib, pkgs, ... }:

{
  xdg.configFile."oh-my-posh/themes/sysinit.omp.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "~/github/personal/roshbhatia/sysinit/modules/darwin/home/omp/theme.json";
    force = true;
  };
}
