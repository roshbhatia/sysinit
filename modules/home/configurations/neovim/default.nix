{
  lib,
  values,
  ...
}:

{
  # Enable stylix neovim target in home-manager
  stylix.targets.neovim = {
    enable = true;
    plugin = "base16-nvim";
    transparentBackground = {
      main = true;
      signColumn = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    # Set flag indicating Nix/home-manager management
    initLua = lib.mkBefore ''
      -- Nix/home-manager management indicator
      vim.g.nix_hm_managed = true

      -- Theme info from Nix
      vim.g.nix_colorscheme = "${values.theme.colorscheme}"
      vim.g.nix_variant = "${values.theme.variant}"
      vim.g.nix_appearance = "${values.theme.appearance}"
    '';
  };

  xdg = {
    configFile = {
      "nvim/init.lua".source = ./init.lua;
      "nvim/after/ftplugin".source = ./after/ftplugin;
      "nvim/after/plugin/".source = ./after/plugin;
      "nvim/after/snippets/".source = ./after/snippets;
      "nvim/after/lsp/".source = ./after/lsp;
      "nvim/lua/sysinit/plugins/".source = ./lua/sysinit/plugins;
      "nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;
      "nvim/lua/sysinit/core".source = ./lua/sysinit/core;
      "nvim/queries".source = ./queries;
    };
  };
}
