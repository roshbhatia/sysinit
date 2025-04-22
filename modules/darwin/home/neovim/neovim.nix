{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    
    # Install base plugins through Nix
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];
  };
  
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };

  home.activation.neovimSetup = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      echo "Setting permissions and ownership for Neovim directories..."
      mkdir -p "$HOME/.local/share/nvim"
      chmod 755 "$HOME/.local/share/nvim"
      chown -R ${config.user.username}:${config.user.username} "$HOME/.local/share/nvim"
      
      mkdir -p "$HOME/.config/nvim"
      chmod 755 "$HOME/.config/nvim"
      chown -R ${config.user.username}:${config.user.username} "$HOME/.config/nvim"
    '';
  };
}