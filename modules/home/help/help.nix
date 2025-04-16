# Help module for sysinit
{ config, lib, pkgs, ... }:

{
  xdg.configFile."sysinit/sysinit-help.sh" = {
    source = ./sysinit-help.sh;
    executable = true;
  };
}
