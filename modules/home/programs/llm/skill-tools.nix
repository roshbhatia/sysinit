{ pkgs, ... }:
{
  home.packages = [
    pkgs.utils
    pkgs.ask
  ];
}
