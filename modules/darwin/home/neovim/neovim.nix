{ config, lib, pkgs, ... }:

{
  xdg.configFile."nvim/init.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./init.lua;
  };

  xdg.configFile."nvim/init.vscode.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./init.vscode.lua;
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink ./lua;
    recursive = true;
  };

  home.activation.neovimSetup = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      echo "Setting permissions and ownership for Neovim directories..."
      NVIM_DIRS=("$HOME/.local/share/nvim" "$HOME/.config/nvim")

      for dir in "''${NVIM_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
          echo "Creating $dir"
          mkdir -p "$dir"
        fi
        echo "Setting ownership and permissions for $dir"
        chown -R "$USER:$(id -g $USER)" "$dir"
        chmod -R u+rw "$dir"
      done

      if [ "$(/usr/bin/defaults read com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled 2>/dev/null)" != "0" ]; then
        echo "Configuring VSCode key repeat settings"
        /usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
      fi
    '';
  };
}
