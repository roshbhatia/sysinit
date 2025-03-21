# Main package file that imports all individual packages
{ config, lib, pkgs, ... }:

{
  imports = [
    ./atuin
    ./git
    ./k9s
    ./macchina
    ./nvim
    ./starship
    ./wezterm
    ./zsh
  ];
}