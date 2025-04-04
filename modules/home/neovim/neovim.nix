{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    
    # For plugins not in nixpkgs, use buildVimPlugin and fetch from GitHub
    plugins = let
      # Build a plugin directly from GitHub
      customVimPlugins = {
        flexoki-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "flexoki-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "kepano";
            repo = "flexoki-neovim";
            rev = "975654bce67514114db89373539621cff42befb5"; # Latest commit hash
            sha256 = "sha256-D8FZXkeoyOzIHjvT/0ubMfLPk691s8xDcAiCagEtMro=";
          };
        };
        mini-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "mini-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "echasnovski";
            repo = "mini.nvim";
            rev = "9af69d8c655e609a7eb043e8f9c27530580d4838"; # Latest commit hash
            sha256 = "sha256-Lha/hfhkxsJAEF2qoD2K8gmYlfQJQlWunikvNbN+7vo="; # Updated hash
          };
        };
        heirline-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "heirline-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "rebelot";
            repo = "heirline.nvim";
            rev = "af3f441ea10f96105e1af14cd37bf213533812d2"; # Latest commit hash
            sha256 = "sha256-VY7I8K0Phekr3gu+QnNbxKRI+8TUVIx5gWYe1Q7gsuI="; # Updated hash
          };
        };
        none-ls-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "none-ls-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "nvimtools";
            repo = "none-ls.nvim";
            rev = "a117163db44c256d53c3be8717f3e1a2a28e6299"; # Latest commit hash
            sha256 = "sha256-KP/mS6HfVbPA5javQdj/x8qnYYk0G6oT0RZaPTAPseM="; # Updated hash
          };
        };
        # We'll build these from source instead of using fetchFromGitHub
        # lsp-zero-nvim and related plugins will be installed directly through vim-plug
      };
    in with pkgs.vimPlugins // customVimPlugins; [
      # Core plugins and UI
      catppuccin-nvim
      tokyonight-nvim
      github-nvim-theme
      flexoki-nvim
      mini-nvim
      nvim-web-devicons
      heirline-nvim  # Statusline, winbar, bufferline, statuscolumn (replacing lualine and barbar)
      indent-blankline-nvim
      which-key-nvim
      nvim-notify
      noice-nvim
      nui-nvim
      codewindow-nvim # Minimap/code preview
      
      # LSP and completion
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim
      mason-tool-installer-nvim  # This exists in nixpkgs
      neodev-nvim  # This exists in nixpkgs
      # lsp-zero-nvim will be loaded through vim-plug
      fidget-nvim
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp_luasnip
      lspkind-nvim
      none-ls-nvim  # Formatting and linting (replaces formatter-nvim and neoformat)
      
      # Snippets
      luasnip
      friendly-snippets
      
      # Treesitter and syntax
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-context
      
      # Telescope and fuzzy finding
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim
      
      # Git integration
      gitsigns-nvim
      
      # File navigation
      nvim-tree-lua
      
      # Terminal
      toggleterm-nvim
      
      # Code utilities
      comment-nvim
      nvim-autopairs
      todo-comments-nvim
      
      # Sessions and startup
      vim-startify
      # auto-session and session-lens-nvim will be loaded through vim-plug
      telescope-ui-select-nvim # For UI selection with Telescope
      
      # Symbol outline and navigation
      aerial-nvim  # Better maintained than symbols-outline
      symbols-outline-nvim # Alternative outline view
      
      # Command line enhancements
      wilder-nvim
      
      # Debugging disabled for now
      
      # Diagnostics
      trouble-nvim  # This exists in nixpkgs
      
      # GitHub Copilot with improved integration
      copilot-lua  # This exists in nixpkgs
      copilot-cmp  # This exists in nixpkgs
    ];
  };
  
  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}