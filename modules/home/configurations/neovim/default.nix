{
  lib,
  values,
  ...
}:

let
  configGen = import ../../../shared/lib/config-gen.nix { inherit lib; };
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
      "nvim/lua/sysinit/config".source = ./lua/sysinit/config;
      "nvim/lua/sysinit/plugins/core/".source = ./lua/sysinit/plugins/core;
      "nvim/lua/sysinit/plugins/debugger/".source = ./lua/sysinit/plugins/debugger;
      "nvim/lua/sysinit/plugins/editor/".source = ./lua/sysinit/plugins/editor;
      "nvim/lua/sysinit/plugins/file/".source = ./lua/sysinit/plugins/file;
      "nvim/lua/sysinit/plugins/git/".source = ./lua/sysinit/plugins/git;
      "nvim/lua/sysinit/plugins/intellicode/".source = ./lua/sysinit/plugins/intellicode;
      "nvim/lua/sysinit/plugins/keymaps/".source = ./lua/sysinit/plugins/keymaps;
      "nvim/lua/sysinit/plugins/library/".source = ./lua/sysinit/plugins/library;
      "nvim/lua/sysinit/plugins/orgmode/".source = ./lua/sysinit/plugins/orgmode;
      "nvim/lua/sysinit/plugins/ui/".source = ./lua/sysinit/plugins/ui;
      "nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;
      "nvim/queries".source = ./queries;
      "nvim/theme_config.json".text = configGen.toJsonFile (themes.generateAppJSON "neovim" values.theme);
    };
  };
}
