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
in
{
  imports = [
    ../shared/options/paths.nix
    ../shared/options/profiles.nix
    ./codesign.nix
    ./programs
    ./packages.nix
  ];

  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = config.sysinit.paths.resolved.stateHome;
  };

  home = {
    stateVersion = "26.05";

    sessionVariables = {
      XDG_CACHE_HOME = config.xdg.cacheHome;
      XDG_CONFIG_HOME = config.xdg.configHome;
      XDG_DATA_HOME = config.xdg.dataHome;
      XDG_STATE_HOME = config.xdg.stateHome;

      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";
      EDITOR = "nvim";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = "1";
      BUILDX_EXPERIMENTAL = "1";

      # prose-gate gets this from its own wrapper. It is here so a bare `vale`
      # finds the same rule set, and so the audit config next to it is reachable
      # as "$(dirname "$SYSINIT_PROSE_STYLE")/vale-audit.ini".
      SYSINIT_PROSE_STYLE = "${pkgs.vale-styles}/vale.ini";
      NODE_NO_WARNINGS = 1;
      NODE_TLS_REJECT_UNAUTHORIZED = 0;
    }
    // (values.environment or { });

    shellAliases = shellLib.aliases;

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
