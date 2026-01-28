{
  lib,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme.nix { inherit lib; };
in

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
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
      "nvim/queries".source = ./queries;
      "nvim/theme_config.json".text = themes.toJsonFile (themes.generateAppJSON "neovim" values.theme);
    };
  };
}
