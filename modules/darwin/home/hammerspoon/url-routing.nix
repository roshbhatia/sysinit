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
  pr = pkgs.sysinit.writeShellScript "open-github-pr" ''
    set -euo pipefail
    export PATH=${lib.escapeShellArg (paths.getPathString config.home.username config.home.homeDirectory)}
    export GH_BROWSER=${browser}
    export BROWSER=${browser}
    exec ${lib.escapeShellArgs cfg.command} "$@"
  '';
in
{
  options.sysinit.hammerspoon.urlRouting = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Route external GitHub PR links through Hammerspoon to WezTerm.";
    };
    browser = lib.mkOption {
      type = lib.types.str;
      default = "org.mozilla.firefox";
      description = "Browser bundle identifier for other links and Dash browser actions.";
    };
    command = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "${config.home.profileDirectory}/bin/gh"
        "dash"
        "pr"
      ];
      description = "Command prefix to open a PR; the URL is appended as one argument.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.browser != "org.hammerspoon.Hammerspoon";
        message = "The URL fallback browser must not route back to Hammerspoon.";
      }
      {
        assertion = cfg.command != [ ] && lib.hasPrefix "/" (builtins.head cfg.command);
        message = "The PR command must begin with an absolute executable path.";
      }
    ];
    xdg.configFile."sysinit/url_routing.json".source = pkgs.sysinit.writeJSON "url-routing.json" {
      inherit (cfg) enable browser;
      command = pr;
      home = config.home.homeDirectory;
      wezterm = "${pkgs.wezterm}/bin/wezterm";
      weztermApp = "${pkgs.wezterm}/Applications/WezTerm.app";
    };
  };
}
