{ config, lib, pkgs, homeDirectory, ... }:

let
  pathLib = import ../../lib/path.nix { inherit lib; };
  loggerLib = import ../../lib/logger.nix { inherit lib; };
in
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  };

  xdg.configFile."nvim/init.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./init.lua;
    force = true;
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./lua;
    force = true;
  };

  home.activation.neovimLogger = loggerLib.mkLogger {
    name = "neovim";
    logDir = "/tmp/log";
    logPrefix = "neovim";
  }.home.activation.neovimLogger;

  home.activation.neovimPathExporter = pathLib.mkPathExporter {
    name = "neovim";
    additionalPaths = [];
  }.home.activation.neovimPathExporter;

  home.activation.neovimPermissions = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
    '';
  };
}
