{
  ...
}:

{
  config,
  pkgs,
  lib,
  ...
}:

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
      HOME = config.home.homeDirectory;
      XCA = config.xdg.cacheHome;
      XCO = config.xdg.configHome;
      XDA = config.xdg.dataHome;
      XDG_CACHE_HOME = config.xdg.cacheHome;
      XDG_CONFIG_HOME = config.xdg.configHome;
      XDG_DATA_HOME = config.xdg.dataHome;
      XDG_STATE_HOME = config.xdg.stateHome;
      XST = config.xdg.stateHome;

      NODE_TLS_REJECT_UNAUTHORIZED = 0;
      NODE_NO_WARNINGS = "1";

      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;

      COLIMA_HOME = "${config.xdg.configHome}/colima";

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
    };

    packages = [
      pkgs.bashInteractive
    ];

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
