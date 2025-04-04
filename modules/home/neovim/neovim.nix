{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # This is set in modules/darwin/system.nix to be VsCode
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    
    # Use minimal plugins from Nix, we'll manage everything with lazy.nvim
    plugins = with pkgs.vimPlugins; [
      # Plugin manager only - everything else managed by lazy
      lazy-nvim
    ];
  };
  
  # Link the Neovim configuration
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
  
  # Install additional packages needed for neovim plugins
  home.packages = with pkgs; [
    # For keystroke visualization plugin (noice.nvim)
    ripgrep
    fd
    MunifTanjim-nui-nvim
    rcarriga-nvim-notify
    folke-noice-nvim
  ];
}