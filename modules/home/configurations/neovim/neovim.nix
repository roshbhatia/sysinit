{
  config,
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
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
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";

  xdg.configFile."nvim/lua/sysinit/pkg".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/pkg";

  xdg.configFile."nvim/lua/sysinit/utils".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/utils";

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/core";
  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/debugger";
  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/editor";
  xdg.configFile."nvim/lua/sysinit/plugins/file/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/file";
  xdg.configFile."nvim/lua/sysinit/plugins/git/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/git";
  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/intellicode";
  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/keymaps";
  xdg.configFile."nvim/lua/sysinit/plugins/library/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/library";
  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/ui";

  xdg.configFile."nvim/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "neovim" values.theme
  );

  xdg.configFile."nvim/after/queries".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/after/queries";

  home.activation.nvimXdgPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.cache/nvim"
    run mkdir -p "${config.home.homeDirectory}/.local/state/nvim"
    run chmod -R u+w "${config.home.homeDirectory}/.cache/nvim" 2>/dev/null || true
    run chmod -R u+w "${config.home.homeDirectory}/.local/state/nvim" 2>/dev/null || true
  '';
}
