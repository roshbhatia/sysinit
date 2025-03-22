{ config, lib, pkgs, ... }:

{
  xdg.configFile = {
    "macchina/themes/rosh.toml" = {
      source = ./themes/rosh.toml;
    };
    
    "macchina/themes/rosh.ascii" = {
      source = ./themes/rosh.ascii;
    };

    "macchina/themes/nix.toml" = {
      source = ./themes/nix.toml;
    };
    
    "macchina/themes/nix.ascii" = {
      source = ./themes/nix.ascii;
    };
  };
}