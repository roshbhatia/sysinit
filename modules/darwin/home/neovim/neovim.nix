{ config, lib, pkgs, ... }:

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
    source = config.lib.file.mkOutOfStoreSymlink "${builtins.getEnv "PWD"}/modules/darwin/home/neovim/init.lua";
    force = true;
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${builtins.getEnv "PWD"}/modules/darwin/home/neovim/lua";
    force = true;
  };

  # Keep only the VSCode key repeat settings
  home.activation.vscodeKeySettings = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      if [ "$(/usr/bin/defaults read com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled 2>/dev/null)" != "0" ]; then
        echo "Configuring VSCode key repeat settings"
        /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
      fi
    '';
  };

}
