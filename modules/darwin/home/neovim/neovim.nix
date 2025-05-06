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

  home.activation.neovimPermissions = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

      chmod -R 755 ${homeDirectory}/.config/nvim

      if [ ! -L "$HOME/.config/nvim/init.lua" ]; then
        ln -s ${homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/init.lua ${homeDirectory}/.config/nvim/init.lua
      fi

      if [ ! -L "$HOME/.config/nvim/lua" ]; then
        ln -s ${homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/lua ${homeDirectory}/.config/nvim/lua
      fi
    '';
  };
}
