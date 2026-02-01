{
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

    initLua = ''
      vim.g.nix_hm_managed = true

      ${builtins.readFile ./init.lua}
    '';
  };

  xdg = {
    configFile = {
      "nvim/after/ftplugin".source = ./after/ftplugin;
      "nvim/after/plugin/".source = ./after/plugin;
      "nvim/after/snippets/".source = ./after/snippets;
      "nvim/after/lsp/".source = ./after/lsp;
      "nvim/lua/sysinit/plugins/".source = ./lua/sysinit/plugins;
      "nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;
      "nvim/queries".source = ./queries;
    };
  };
}
