{
  config,
  pkgs,
  lib,
  values ? { },
  ...
}:
let
  shellLib = import ../lib/shell.nix {
    inherit lib;
  };
  
  # For Lima VMs, use the mounted home directory instead of the nix home
  homePrefix = if (values.isLima or false) then "/home/${values.user.username}" else config.home.homeDirectory;
in
{
  imports = [
    ./programs
    ./packages.nix
  ];

  xdg = {
    enable = true;
    cacheHome = "${homePrefix}/.cache";
    configHome = "${homePrefix}/.config";
    dataHome = "${homePrefix}/.local/share";
    stateHome = "${homePrefix}/.local/state";
  };

  home = {
    stateVersion = "23.11";

    sessionVariables = {
      # XDG Base Directory
      XDG_CACHE_HOME = config.xdg.cacheHome;
      XDG_CONFIG_HOME = config.xdg.configHome;
      XDG_DATA_HOME = config.xdg.dataHome;
      XDG_STATE_HOME = config.xdg.stateHome;

      # Locale
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # Editors
      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";
      EDITOR = "nvim";

      # Tool-specific
      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      BUILDX_EXPERIMENTAL = "1";
      NODE_NO_WARNINGS = 1;
      NODE_TLS_REJECT_UNAUTHORIZED = 0;
    } // (values.environment or { });

    shellAliases = shellLib.aliases;

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
