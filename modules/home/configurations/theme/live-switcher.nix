{ lib, pkgs, config, values, utils, ... }:

with lib;

{
  imports = [
    ../../../lib/theme/live-switcher.nix
    ../../../lib/validation-integration.nix
  ];

  config = {
    xdg.configFile."nvim/lua/sysinit/theme/live-switcher.lua" = {
      source = ../neovim/lua/sysinit/theme/live-switcher.lua;
    };
  };
}
