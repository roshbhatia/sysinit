{ config, lib, pkgs, homeDirectory ... }:

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

  home.activation.vscodeKeySettings = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      if [ "$(/usr/bin/defaults read com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled 2>/dev/null)" != "0" ]; then
        /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
      fi

      NVIM_DIR="${homeDirectory}/.config/nvim"
      if [ -d "$NVIM_DIR" ]; then
        /bin/chmod -R u+rwx "$NVIM_DIR"
        /bin/chmod -R go-wx "$NVIM_DIR"
      fi
    '';
  };
}
