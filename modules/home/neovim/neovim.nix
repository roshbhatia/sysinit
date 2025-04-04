{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];
  };
  
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}