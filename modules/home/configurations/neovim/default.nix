{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  inherit (config.lib.file) mkOutOfStoreSymlink;
  sysinitPath = builtins.getEnv "SYSINIT_PATH";
  pathOrDefault =
    if sysinitPath != "" then
      sysinitPath
    else
      "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
  nvimConfigPath = "${pathOrDefault}/modules/home/configurations/neovim";
in

{
  stylix.targets.neovim.enable = false;
  stylix.targets.vim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim/init.lua".source = mkOutOfStoreSymlink "${nvimConfigPath}/init.lua";

  xdg.configFile."nvim/lua/sysinit/config".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/config";

  xdg.configFile."nvim/lua/sysinit/utils".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/utils";

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/core";
  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/debugger";
  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/editor";
  xdg.configFile."nvim/lua/sysinit/plugins/file/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/file";
  xdg.configFile."nvim/lua/sysinit/plugins/git/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/git";
  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/intellicode";
  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/keymaps";
  xdg.configFile."nvim/lua/sysinit/plugins/library/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/library";
  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/ui";

  xdg.configFile."nvim/lua/sysinit/plugins/orgmode/".source =
    mkOutOfStoreSymlink "${nvimConfigPath}/lua/sysinit/plugins/orgmode";

  xdg.configFile."nvim/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "neovim" values.theme
  );

  xdg.configFile."nvim/queries".source = mkOutOfStoreSymlink "${nvimConfigPath}/queries";
}
