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
      kinds = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "pull"
            "actions"
          ]
        );
        default = [ "pull" ];
        description = "Link kinds this provider supports.";
      };
      urlTemplate = lib.mkOption {
        type = lib.types.str;
        default = "{{ .URL }}";
        description = "Provider URL template with URL, Owner, Repo, and Number fields.";
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
      providers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Provider names offered for this link kind, in initial picker order.";
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
    providers = lib.mkOption {
      type = lib.types.attrsOf targetType;
      default = { };
      description = "URL providers rendered as provider/v1 manifests; downstream flakes can add providers.";
    };
    manifests = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "provider/v1 JSON manifests implementing url.pull or url.actions and returning a URL target.";
    };
    routes = lib.mkOption {
      type = lib.types.attrsOf routeType;
      description = ''
        Targets per link kind the router recognises. The keys are the kinds
        `url_routing.lua` matches: `pull` and `actions`.
      '';
      default = { };
    };
  };

  config =
    let
      targets = lib.attrValues cfg.providers;
      selected = lib.unique (lib.concatMap (route: route.providers) (lib.attrValues cfg.routes));
      manifests = lib.mapAttrs (
        name: target:
        pkgs.sysinit.writeJSON "url-provider-${name}.json" {
          version = "provider/v1";
          inherit name;
          description = target.name;
          command = [
            "${pkgs.sysinit-gotools}/bin/url-route"
            "emit"
          ];
          actions = lib.genAttrs (map (kind: "url.${kind}") target.kinds) (_: {
            description = if target.detail != null then target.detail else target.name;
            argv = [
              (builtins.toJSON (
                {
                  inherit (target) name;
                  url = target.urlTemplate;
                }
                // lib.optionalAttrs (target.detail != null) { inherit (target) detail; }
                // (
                  if target.bundle != null then
                    { inherit (target) bundle; }
                  else
                    { command = targetScript name target; }
                )
              ))
            ];
          });
        }
      ) cfg.providers;
      providerDirectory = pkgs.linkFarm "url-providers" (
        lib.mapAttrsToList (name: path: {
          name = "${name}.json";
          inherit path;
        }) cfg.manifests
      );
    in
    {
      sysinit.hammerspoon.urlRouting = {
        inherit manifests;
        providers = import ./url-providers {
          inherit config;
          inherit (cfg) browser;
        };
        routes = {
          pull = {
            verb = "Review";
            providers = [
              "gh-dash"
              "browser"
              "octo"
              "atlas"
              "diffview"
              "changes"
              "hunk"
            ];
          };
          actions = {
            verb = "Watch";
            providers = [
              "gh-enhance"
              "browser"
            ];
          };
        };
      };
      assertions = [
        {
          assertion = cfg.browser != "org.hammerspoon.Hammerspoon";
          message = "The URL fallback browser must not route back to Hammerspoon.";
        }
        {
          assertion = lib.all (route: route.providers != [ ]) (lib.attrValues cfg.routes);
          message = "Each URL route must offer at least one provider.";
        }
        {
          assertion = lib.all (name: builtins.hasAttr name cfg.manifests) selected;
          message = "Each URL route must reference an installed provider.";
        }
        {
          assertion = lib.all (
            kind:
            lib.all (
              name: !builtins.hasAttr name cfg.providers || lib.elem kind cfg.providers.${name}.kinds
            ) cfg.routes.${kind}.providers
          ) (builtins.attrNames cfg.routes);
          message = "Each URL provider must support its configured route kind.";
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
        inherit (cfg) routes;
        providerDirectory = "${providerDirectory}";
        resolver = "${pkgs.sysinit-gotools}/bin/url-route";
        home = config.home.homeDirectory;
        wezterm = "${pkgs.wezterm}/bin/wezterm";
        weztermApp = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app";
      };
    };
}
