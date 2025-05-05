{ config, lib, pkgs, ... }:

{
  xdg.configFile."oh-my-posh/themes/sysinit.omp.json" = {
    source = config.lib.file.mkOutOfStoreSymlink ./theme.json;
    force = true;
  };
}
