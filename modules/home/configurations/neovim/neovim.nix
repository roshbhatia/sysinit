{
  config,
  lib,
  overlay,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette overlay.theme.colorscheme overlay.theme.variant;
  appTheme = themes.appThemes.neovim.${overlay.theme.colorscheme};

  themeConfig = {
    colorscheme = overlay.theme.colorscheme;
    variant = overlay.theme.variant;
    transparency = overlay.theme.transparency;
    appTheme = appTheme;
    palette = palette;
  };
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
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";

  xdg.configFile."nvim/lua/sysinit/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/config";

  xdg.configFile."nvim/lua/sysinit/pkg".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/pkg";

  xdg.configFile."nvim/lua/sysinit/plugins/core/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/core";
  xdg.configFile."nvim/lua/sysinit/plugins/debugger/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/debugger";
  xdg.configFile."nvim/lua/sysinit/plugins/editor/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/editor";
  xdg.configFile."nvim/lua/sysinit/plugins/file/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/file";
  xdg.configFile."nvim/lua/sysinit/plugins/git/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/git";
  xdg.configFile."nvim/lua/sysinit/plugins/intellicode/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/intellicode";
  xdg.configFile."nvim/lua/sysinit/plugins/keymaps/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/keymaps";
  xdg.configFile."nvim/lua/sysinit/plugins/library/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/library";
  xdg.configFile."nvim/lua/sysinit/plugins/notes/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/notes";
  xdg.configFile."nvim/lua/sysinit/plugins/ui/".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/plugins/ui";

  xdg.configFile."nvim/lua/sysinit/theme_config.lua".text = ''
    -- Auto-generated theme configuration
    local M = {}

    M.colorscheme = "${themeConfig.colorscheme}"
    M.variant = "${themeConfig.variant}"
    M.transparency = {
      enable = ${if themeConfig.transparency.enable then "true" else "false"},
      opacity = ${toString themeConfig.transparency.opacity}
    }

    M.plugins = {
      ${themeConfig.colorscheme} = {
        plugin = "${appTheme.plugin}",
        name = "${appTheme.name}",
        setup = "${appTheme.setup}",
        colorscheme = "${appTheme.colorscheme}"
      }
    }

    M.palette = {
      ${lib.concatStringsSep ",\n      " (
        lib.mapAttrsToList (name: value: "${name} = \"${value}\"") palette
      )}
    }

    return M
  '';

  home.activation.nvimXdgPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.cache/nvim"
    run mkdir -p "${config.home.homeDirectory}/.local/state/nvim"
    run chmod -R u+w "${config.home.homeDirectory}/.cache/nvim" 2>/dev/null || true
    run chmod -R u+w "${config.home.homeDirectory}/.local/state/nvim" 2>/dev/null || true
  '';
}
