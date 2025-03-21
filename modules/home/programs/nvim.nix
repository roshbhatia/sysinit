{ config, lib, pkgs, ... }:

{
  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      # Plugin manager
      lazy-nvim
      
      # Core plugins
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      friendly-snippets
      lspkind-nvim
      telescope-nvim
      plenary-nvim
      nvim-treesitter
      
      # UI enhancements
      nvim-web-devicons
      nvim-tree-lua
      barbar-nvim
      vim-startify
      codewindow-nvim
      wilder-nvim
      trouble-nvim
      which-key-nvim
      
      # Utilities
      gitsigns-nvim
      nvim-autopairs
      indent-blankline-nvim
      nvim-comment
      toggleterm-nvim
      symbols-outline-nvim
    ];
  };
  
  # Copy the custom Neovim configuration files
  xdg.configFile = {
    "nvim" = {
      source = ../../../nvim;
      recursive = true;
    };
  };
}