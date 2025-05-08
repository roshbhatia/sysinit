{ config, lib, pkgs, homeDirectory, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ${homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/wezterm.lua;
    force = true;
  };
}
