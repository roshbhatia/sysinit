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

      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      EDITOR = "nvim";
      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";

      NODE_NO_WARNINGS = 1;
      NODE_TLS_REJECT_UNAUTHORIZED = 0;
    };

    shellAliases = {
      sudo = "sudo -E";

      f = "yazi";
      h = "hx";
      vimdiff = "nvim -n -c 'DiffviewOpen'";

      sg = "ast-grep";

      lg = "lazygit";

      k = "kubectl";
      kg = "kubectl get";
      kd = "kubectl describe";
      ke = "kubectl edit";
      ka = "kubectl apply";
      kpf = "kubectl port-forward";
      kdel = "kubectl delete";
      klog = "kubectl logs";
    };

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
