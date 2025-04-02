{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };
}