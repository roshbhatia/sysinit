{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  inherit (config.lib.file) mkOutOfStoreSymlink;
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

  xdg.configFile."nvim/init.lua".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";

  xdg.configFile."nvim/lua/sysinit/config".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/config";

  xdg.configFile."nvim/lua/sysinit/utils".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/utils";

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/core";
  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/debugger";
  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/editor";
  xdg.configFile."nvim/lua/sysinit/plugins/file/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/file";
  xdg.configFile."nvim/lua/sysinit/plugins/git/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/git";
  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/intellicode";
  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/keymaps";
  xdg.configFile."nvim/lua/sysinit/plugins/library/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/library";
  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/ui";

  xdg.configFile."nvim/lua/sysinit/plugins/orgmode/".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/orgmode";

  xdg.configFile."nvim/theme_config.json".text = themes.generateAppJSON "neovim" values.theme;

  xdg.configFile."nvim/agents_config.json".text = builtins.toJSON {
    agents = values.llm.agents;
  };

  xdg.configFile."nvim/queries".source =
    mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/queries";
}
