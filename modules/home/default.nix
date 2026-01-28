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
  appTheme = themes.getAppTheme "vivid" values.theme.colorscheme values.theme.variant;
  shellEnv = shellLib.env {
    inherit colors appTheme;
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
    ./packages.nix
    ./package-managers.nix
    ./shell-tools.nix
    ./files.nix
    ./editors.nix
    ./kubernetes.nix
    ./terminal.nix
    ./dev-tools.nix
    ./nushell.nix
    ./ssh.nix
    ./omp.nix
    ./git
    ./zsh
    ./neovim
    ./llm
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
      BEADS_DIR = "${config.xdg.dataHome}/.beads";
    }
    // shellEnv;

    shellAliases = allAliases;

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
