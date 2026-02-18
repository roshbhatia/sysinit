{
  config,
  pkgs,
  lib,
  ...
}:
let
  shellLib = import ../lib/shell.nix {
    inherit lib;
  };
  shellEnv = shellLib.env { };
  allAliases = shellLib.aliases // {
    tree = "eza --tree --icons=never";
    org = "nvim ~/org/notes";
    cat = "bat -pp";
    ll = "eza --icons=always -l -a";
  };
in
{
  imports = [
    ./programs
    ./packages.nix
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
