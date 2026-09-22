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
  targetScript =
    kind: target:
    pkgs.sysinit.writeShellScript "open-github-${kind}-${slug target.name}" ''
      set -euo pipefail
      export PATH=${lib.escapeShellArg (paths.getPathString config.home.username config.home.homeDirectory)}
      export GH_BROWSER=${browser}
      export BROWSER=${browser}
      exec ${lib.escapeShellArgs target.command} "$@"
    '';
  targetType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Row label shown in the picker.";
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
  routeType = lib.types.submodule {
    options = {
      verb = lib.mkOption {
        type = lib.types.str;
        default = "Open";
        description = "What the picker says choosing a row does.";
      };
      targets = lib.mkOption {
        type = lib.types.listOf targetType;
        default = [ ];
        description = "Targets offered for this link kind. The first row is preselected.";
      };
    };
  };
in
{
  options.sysinit.hammerspoon.urlRouting = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Route external GitHub links through Hammerspoon to a picker.";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "org.mozilla.firefox";
      description = "Browser bundle identifier for other links and Dash browser actions.";
    };
    routes = lib.mkOption {
      type = lib.types.attrsOf routeType;
      description = ''
        Targets per link kind the router recognises. The keys are the kinds
        `url_routing.lua` matches: `pull` and `actions`.
      '';
      default = {
        pull = {
          verb = "Review";
          targets = [
            {
              name = "gh dash";
              detail = "Dashboard, checks, and review actions";
              command = [
                "${config.home.profileDirectory}/bin/gh"
                "dash"
              ];
            }
            {
              name = "Neovim";
              detail = "Octo overview with existing threads";
              command = [
                "${config.home.profileDirectory}/bin/gh-pr-diff"
                "--overview"
              ];
            }
            {
              name = "Firefox";
              detail = "Open the PR on github.com";
              bundle = cfg.browser;
            }
          ];
        };
        actions = {
          verb = "Watch";
          targets = [
            {
              name = "gh enhance";
              detail = "Watch the run's jobs and logs";
              command = [
                "${config.home.profileDirectory}/bin/gh"
                "enhance"
              ];
            }
            {
              name = "Firefox";
              detail = "Open the run on github.com";
              bundle = cfg.browser;
            }
          ];
        };
      };
    };
  };

  config =
    let
      targets = lib.concatMap (route: route.targets) (lib.attrValues cfg.routes);
    in
    {
      assertions = [
        {
          assertion = cfg.browser != "org.hammerspoon.Hammerspoon";
          message = "The URL fallback browser must not route back to Hammerspoon.";
        }
        {
          assertion = lib.all (route: route.targets != [ ]) (lib.attrValues cfg.routes);
          message = "Each URL route must offer at least one target.";
        }
        {
          assertion = lib.all (target: (target.command != [ ]) != (target.bundle != null)) targets;
          message = "Each URL target must set exactly one of command or bundle.";
        }
        {
          assertion = lib.all (
            target: target.command == [ ] || lib.hasPrefix "/" (builtins.head target.command)
          ) targets;
          message = "A URL target command must begin with an absolute executable path.";
        }
        {
          assertion = lib.all (target: target.bundle != "org.hammerspoon.Hammerspoon") targets;
          message = "A URL target bundle must not route back to Hammerspoon.";
        }
      ];
      xdg.configFile."sysinit/url_routing.json".source = pkgs.sysinit.writeJSON "url-routing.json" {
        inherit (cfg) enable browser;
        routes = lib.mapAttrs (kind: route: {
          inherit (route) verb;
          targets = map (
            target:
            {
              inherit (target) name;
            }
            // lib.optionalAttrs (target.detail != null) { inherit (target) detail; }
            // (
              if target.bundle != null then
                { inherit (target) bundle; }
              else
                { command = targetScript kind target; }
            )
          ) route.targets;
        }) cfg.routes;
        home = config.home.homeDirectory;
        wezterm = "${pkgs.wezterm}/bin/wezterm";
        weztermApp = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app";
      };
    };
}
