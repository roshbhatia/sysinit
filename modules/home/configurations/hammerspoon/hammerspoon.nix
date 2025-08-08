{ config, lib, values, ... }:
{
  home.file."${config.xdg.configHome}/hammerspoon/init.lua".source = ./init.lua;
  home.file."${config.xdg.configHome}/hammerspoon/lua/app_switcher.lua".source = ./lua/app_switcher.lua;
}
