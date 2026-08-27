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

      # prose-gate gets this from its own wrapper. It is here so the audit
      # config next to it is reachable as
      # "$(dirname "$SYSINIT_PROSE_STYLE")/vale-audit.ini".
      #
      # It does NOT make a bare `vale` find the rule set, which an earlier
      # comment here claimed: vale reads ~/.vale.ini and never this variable.
      # That gap is why another session wrote its own Sysinit style by hand.
      # `home.file.".vale.ini"` below closes it.
      SYSINIT_PROSE_STYLE = "${pkgs.vale-styles}/vale.ini";
    }
    // (values.environment or { });

    shellAliases = shellLib.aliases;

    # A bare `vale` reads this and nothing else, so without it the rule set this
    # repository states was unreachable outside the hook. It points at the audit
    # config: a person linting a doc by hand wants the suggestion floor and the
    # borrowed styles. The hook runs at the error floor with neither.
    #
    # The hook passes --no-global, so this file can never redefine the gate. That
    # separation is deliberate: a hand-written Sysinit style under
    # ~/.local/share/vale/styles once replaced all 22 rules with 12 of its own,
    # and the hook reported their messages with no sign the set had changed.
    file.".vale.ini" = {
      source = "${pkgs.vale-styles}/vale-audit.ini";
      force = true;
    };

    activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      export PATH="${pkgs.bashInteractive}/bin:$PATH"
    '';
  };
}
