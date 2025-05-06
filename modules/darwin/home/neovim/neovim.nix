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

  # Keep only the VSCode key repeat settings
  home.activation.vscodeKeySettings = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      if [ "$(/usr/bin/defaults read com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled 2>/dev/null)" != "0" ]; then
        echo "Configuring VSCode key repeat settings"
        /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
      fi

      # Ensure the user has read/write permissions to the nvim folder and its subfolders
      NVIM_DIR="${homeDirectory}/.config/nvim"
      if [ -d "$NVIM_DIR" ]; then
        echo "Setting read/write permissions for $NVIM_DIR"
        /bin/chmod -R u+rw "$NVIM_DIR"
      fi
    '';
  };

}
