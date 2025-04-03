{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # This is set in modules/darwin/system.nix to be VsCode
    defaultEditor = false;
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
      nvim-treesitter-textobjects
      
      # UI enhancements
      nvim-web-devicons
      nvim-tree-lua
      barbar-nvim
      vim-startify
      codewindow-nvim
      wilder-nvim
      trouble-nvim
      which-key-nvim
      aerial-nvim
      
      # Utilities
      gitsigns-nvim
      nvim-autopairs
      nvim-comment
      toggleterm-nvim
      symbols-outline-nvim
      formatter-nvim
      telescope-fzf-native-nvim
      copilot-lua
      copilot-cmp
      neoformat
      vim-visual-multi
      nvim-treesitter-context
      todo-comments-nvim
      git-blame-nvim
    ];
  };
  
  # Link the Neovim configuration
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}