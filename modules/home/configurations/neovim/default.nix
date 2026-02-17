{
  config,
  ...
}:

let
  themeConfig = {
    colorscheme = config.sysinit.theme.colorscheme;
    variant = config.sysinit.theme.variant;
    appearance = config.sysinit.theme.appearance;
    transparency = config.sysinit.theme.transparency;
  };
in
{
  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    initLua = ''
      -- Injected by home-manager
      vim.g.nix_managed = true

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
      "nvim/theme_config.json".text = builtins.toJSON themeConfig;
    };
  };
}
