{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.hammerspoon.urlRouting;
  paths = import ../../../lib/paths.nix { inherit lib; };
  browser = pkgs.sysinit.writeShellScript "pr-browser" ''
    set -euo pipefail
    exec /usr/bin/open -b ${lib.escapeShellArg cfg.browser} "$@"
  '';
  slug =
    name:
    lib.strings.sanitizeDerivationName (
      lib.toLower (builtins.replaceStrings [ " " "(" ")" ] [ "-" "" "" ] name)
    );
  reviewerScript =
    reviewer:
    pkgs.sysinit.writeShellScript "open-github-pr-${slug reviewer.name}" ''
      set -euo pipefail
      export PATH=${lib.escapeShellArg (paths.getPathString config.home.username config.home.homeDirectory)}
      export GH_BROWSER=${browser}
      export BROWSER=${browser}
      exec ${lib.escapeShellArgs reviewer.command} "$@"
    '';
  reviewerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Row label shown in the review picker.";
      };
      detail = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Second line shown under the row label.";
      };
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Command prefix opened in WezTerm; the URL is appended as one argument.";
      };
      bundle = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Application bundle identifier that opens the URL instead of a command.";
      };
    };
  };
in
{
  options.sysinit.hammerspoon.urlRouting = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Route external GitHub PR links through Hammerspoon to a review picker.";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "org.mozilla.firefox";
      description = "Browser bundle identifier for other links and Dash browser actions.";
    };
    reviewers = lib.mkOption {
      type = lib.types.listOf reviewerType;
      description = "Review targets offered for a PR link. The first row is preselected.";
      default = [
        {
          name = "gh dash";
          detail = "Dashboard, checks, and review actions";
          command = [
            "${config.home.profileDirectory}/bin/gh"
            "dash"
          ];
        }
        {
          name = "Neovim (Octo)";
          detail = "Octo diff with existing threads";
          command = [ "${config.home.profileDirectory}/bin/gh-pr-diff" ];
        }
        {
          name = "Firefox";
          detail = "Open the PR on github.com";
          bundle = cfg.browser;
        }
      ];
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.browser != "org.hammerspoon.Hammerspoon";
        message = "The URL fallback browser must not route back to Hammerspoon.";
      }
      {
        assertion = cfg.reviewers != [ ];
        message = "The PR review picker must offer at least one reviewer.";
      }
      {
        assertion = lib.all (
          reviewer: (reviewer.command != [ ]) != (reviewer.bundle != null)
        ) cfg.reviewers;
        message = "Each PR reviewer must set exactly one of command or bundle.";
      }
      {
        assertion = lib.all (
          reviewer: reviewer.command == [ ] || lib.hasPrefix "/" (builtins.head reviewer.command)
        ) cfg.reviewers;
        message = "A PR reviewer command must begin with an absolute executable path.";
      }
      {
        assertion = lib.all (reviewer: reviewer.bundle != "org.hammerspoon.Hammerspoon") cfg.reviewers;
        message = "A PR reviewer bundle must not route back to Hammerspoon.";
      }
    ];
    xdg.configFile."sysinit/url_routing.json".source = pkgs.sysinit.writeJSON "url-routing.json" {
      inherit (cfg) enable browser;
      reviewers = map (
        reviewer:
        {
          inherit (reviewer) name;
        }
        // lib.optionalAttrs (reviewer.detail != null) { inherit (reviewer) detail; }
        // (
          if reviewer.bundle != null then
            { inherit (reviewer) bundle; }
          else
            { command = reviewerScript reviewer; }
        )
      ) cfg.reviewers;
      home = config.home.homeDirectory;
      wezterm = "${pkgs.wezterm}/bin/wezterm";
      weztermApp = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app";
    };
  };
}
