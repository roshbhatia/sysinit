{ config, lib, pkgs, ... }:

{
  # Macchina configuration via xdg paths
  xdg.configFile = {
    "macchina/themes/rosh.toml" = {
      source = ./themes/rosh.toml;
    };
    
    "macchina/themes/rosh.ascii" = {
      source = ./rosh.ascii;
    };
  };
}