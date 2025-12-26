{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
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
  };

  xdg.configFile."nvim/init.lua".source = ./init.lua;

  xdg.configFile."nvim/lua/sysinit/config".source = ./lua/sysinit/config;

  xdg.configFile."nvim/lua/sysinit/utils".source = ./lua/sysinit/utils;

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source = ./lua/sysinit/plugins/core;

  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source = ./lua/sysinit/plugins/debugger;

  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source = ./lua/sysinit/plugins/editor;

  xdg.configFile."nvim/lua/sysinit/plugins/file/".source = ./lua/sysinit/plugins/file;

  xdg.configFile."nvim/lua/sysinit/plugins/git/".source = ./lua/sysinit/plugins/git;

  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source = ./lua/sysinit/plugins/intellicode;

  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source = ./lua/sysinit/plugins/keymaps;

  xdg.configFile."nvim/lua/sysinit/plugins/library/".source = ./lua/sysinit/plugins/library;

  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source = ./lua/sysinit/plugins/ui;

  xdg.configFile."nvim/lua/sysinit/plugins/orgmode/".source = ./lua/sysinit/plugins/orgmode;

  xdg.configFile."nvim/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "neovim" values.theme
  );

  xdg.configFile."nvim/lua/sysinit/generated/theme_map.lua".text =
    themes.adapters.neovim.generateThemeLuaMap themes.themes;

  xdg.configFile."nvim/queries".source = ./queries;
}
