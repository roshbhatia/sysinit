{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
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
      # After directory - loaded after all other runtime paths
      # See :help after-directory for details
      "nvim/after/ftplugin".source = ./after/ftplugin; # Filetype-specific settings
      "nvim/after/plugin/".source = ./after/plugin; # Post-load plugin overrides
      "nvim/after/snippets/".source = ./after/snippets; # Language-organized snippets
      "nvim/after/lsp/".source = ./after/lsp; # LSP config overrides (highest priority)
      "nvim/lua/sysinit/config".source = ./lua/sysinit/config;
      # Plugin directories (auto-discovered by lazy.nvim via import)
      # Organized following kickstart/lazyvim conventions
      "nvim/lua/sysinit/plugins/coding/".source = ./lua/sysinit/plugins/coding;
      "nvim/lua/sysinit/plugins/dap/".source = ./lua/sysinit/plugins/dap;
      "nvim/lua/sysinit/plugins/editor/".source = ./lua/sysinit/plugins/editor;
      "nvim/lua/sysinit/plugins/git/".source = ./lua/sysinit/plugins/git;
      "nvim/lua/sysinit/plugins/lang/".source = ./lua/sysinit/plugins/lang;
      "nvim/lua/sysinit/plugins/lsp/".source = ./lua/sysinit/plugins/lsp;
      "nvim/lua/sysinit/plugins/util/".source = ./lua/sysinit/plugins/util;
      # UI plugins (includes modular themes/ subdirectory)
      "nvim/lua/sysinit/plugins/ui/".source = ./lua/sysinit/plugins/ui;
      # Utilities (includes code_actions/ and ai/ subdirectories)
      "nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;
      "nvim/queries".source = ./queries;
      "nvim/theme_config.json".text = themes.toJsonFile (themes.generateAppJSON "neovim" values.theme);
    };
  };
}
