{
  values,
  ...
}:

{
  stylix.targets.neovim.plugin = "base16-nvim";

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

      vim.g.nix_transparency_enabled = ${
        if values.theme.transparency.opacity < 1.0 then "true" else "false"
      }
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
