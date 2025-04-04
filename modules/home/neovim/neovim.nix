{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
      tokyonight-nvim
      github-nvim-theme
      telescope-nvim
      plenary-nvim
      nvim-treesitter
      nvim-tree-lua
      nvim-web-devicons
      mason-nvim
      mason-lspconfig-nvim
      nvim-lspconfig
      vim-startify
      indent-blankline-nvim
    ];
  };
  
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}