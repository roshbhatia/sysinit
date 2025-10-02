{
  config,
  pkgs,
  lib,
  values,
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

      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";

      NODE_NO_WARNINGS = 1;
      NODE_TLS_REJECT_UNAUTHORIZED = 0;
    }
    // lib.optionalAttrs (values.darwin.colima.enable or false) {
      COLIMA_HOME = "${config.xdg.configHome}/colima";
      DOCKER_CONTEXT = "colima";
      DOCKER_HOST = "unix:///${config.xdg.configHome}/colima/default/docker.sock";
    }
    // lib.optionalAttrs (values.darwin.podman.enable or false) {
      DOCKER_CONTEXT = "podman-desktop";
    };

    packages = [
      pkgs.bashInteractive
    ];

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
