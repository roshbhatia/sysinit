{ config, lib, pkgs, ... }:

{
  xdg.configFile."wezterm/wezterm.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "~/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/wezterm.lua";
    force = true;
  };
}
