{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = lib.importTOML ./starship.toml;
  };
}