{ config, lib, pkgs, homeDirectory, ... }:

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
    source = ./init.lua;
    force = true;
  };

  xdg.configFile."nvim/lua" = {
    source = ./lua;
    force = true;
  };

  home.activation.neovimPermissions = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

      chmod -R 755 "$HOME/.config/nvim"
    '';
  };
}
