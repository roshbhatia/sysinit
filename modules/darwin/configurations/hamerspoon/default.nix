{ config, pkgs, lib, ... }:
{
  config = {
    home.file.".hammerspoon/init.lua".source = ./init.lua;
    home.file.".hammerspoon/lua/app_switcher.lua".source = ./lua/app_switcher.lua;
  };
}
