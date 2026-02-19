{
  config,
  pkgs,
  lib,
  ...
}:
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
    };

    shellAliases = shellLib.aliases;

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
