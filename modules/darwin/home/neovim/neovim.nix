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
    source = config.lib.file.mkOutOfStoreSymlink ./init.lua;
    force = true;
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./lua;
    force = true;
  };

  home.activation.neovimPermissions = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

      NVIM_DIR="${homeDirectory}/.config/nvim"
      /etc/profiles/per-user/rshnbhatia/bin/chmod-R u+rwx "$NVIM_DIR"
      /etc/profiles/per-user/rshnbhatia/bin/chmod -R go-wx "$NVIM_DIR"
      fi
    '';
  };
}
