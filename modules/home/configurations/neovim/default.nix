{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  nvimConfigPath = ./.;
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

  xdg.configFile."nvim/init.lua".source = "${nvimConfigPath}/init.lua";

  xdg.configFile."nvim/lua/sysinit/config".source = "${nvimConfigPath}/lua/sysinit/config";

  xdg.configFile."nvim/lua/sysinit/utils".source = "${nvimConfigPath}/lua/sysinit/utils";

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/core";
  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/debugger";
  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/editor";
  xdg.configFile."nvim/lua/sysinit/plugins/file/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/file";
  xdg.configFile."nvim/lua/sysinit/plugins/git/".source = "${nvimConfigPath}/lua/sysinit/plugins/git";
  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/intellicode";
  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/keymaps";
  xdg.configFile."nvim/lua/sysinit/plugins/library/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/library";
  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source = "${nvimConfigPath}/lua/sysinit/plugins/ui";

  xdg.configFile."nvim/lua/sysinit/plugins/orgmode/".source =
    "${nvimConfigPath}/lua/sysinit/plugins/orgmode";

  xdg.configFile."nvim/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "neovim" values.theme
  );

  xdg.configFile."nvim/queries".source = "${nvimConfigPath}/queries";
}
