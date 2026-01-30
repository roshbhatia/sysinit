{
  config,
  pkgs,
  lib,
  values,
  ...
}:
let
  shellLib = import ../shared/lib/shell.nix {
    inherit lib;
  };
  themes = import ../shared/lib/theme.nix {
    inherit lib;
  };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;
  shellEnv = shellLib.env {
    inherit colors;
  };
  allAliases = shellLib.aliases // {
    f = "yazi";
    tree = "eza --tree --icons=never";
    org = "nvim ~/org/notes";
    cat = "bat -pp";
    ll = "eza --icons=always -l -a";
  };
in
{
  imports = [
    ./configurations
    ./packages
  ];

  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  home = {
    stateVersion = "23.11";

    sessionVariables = {
      XDG_CACHE_HOME = config.xdg.cacheHome;
      XDG_CONFIG_HOME = config.xdg.configHome;
      XDG_DATA_HOME = config.xdg.dataHome;
      XDG_STATE_HOME = config.xdg.stateHome;

      NODE_NO_WARNINGS = 1;
      NODE_TLS_REJECT_UNAUTHORIZED = 0;
    }
    // shellEnv;

    shellAliases = allAliases;

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
