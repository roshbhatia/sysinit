{ pkgs, ... }:
{
  home.packages = [
    pkgs.sysinit-utils
    pkgs.ask
    pkgs.calldiff
  ];

}
