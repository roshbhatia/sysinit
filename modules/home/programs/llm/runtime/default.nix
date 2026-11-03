{
  pkgs,
  lib,
  notificationSettings ? { },
  iconOverrides ? { },
}:
let
  registry = import ../harnesses/registry.nix;

  svgs =
    (builtins.mapAttrs (name: _h: ./icons/${name}.svg) (lib.filterAttrs (_name: h: h.ownIcon) registry))
    // {
      agent = ./icons/agent.svg;
    }
    // iconOverrides;

  paths = builtins.readFile (pkgs.agent-signals-source + "/runtime/paths.sh");

  group = builtins.readFile (pkgs.agent-signals-source + "/runtime/agent-group.sh");

  busyPanes = builtins.readFile (pkgs.agent-signals-source + "/runtime/agent-busy-panes.sh");

  joinFragments = lib.concatStringsSep "\n";

  iconCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: src:
      "rsvg-convert --width 256 --height 256 --keep-aspect-ratio --background-color '#FFFFFF' ${lib.escapeShellArg "${src}"} --output \"$out\"/${lib.escapeShellArg "${name}.png"}"
    ) svgs
  );

  iconSources = pkgs.writeText "agent-notify-icon-sources.json" (builtins.toJSON svgs);
  icons =
    pkgs.runCommand "agent-notify-icons"
      {
        nativeBuildInputs = [
          pkgs.librsvg
          pkgs.python3
        ];
      }
      ''
        python3 ${./check-icons.py} ${iconSources}
        mkdir -p "$out"
        ${iconCommands}
        python3 ${./check-icons.py} ${iconSources} "$out"
      '';

  script = pkgs.mkAgentNotifier {
    inherit pkgs;
    settings = lib.recursiveUpdate {
      defaultIcon = "${icons}/agent.png";
      agents = lib.mapAttrs (name: h: {
        inherit (h) label;
        icon = "${icons}/${if builtins.hasAttr name svgs then name else "agent"}.png";
      }) registry;
    } notificationSettings;
  };

  promptScript = pkgs.sysinit.writeShellApplication {
    name = "agent-prompt";
    runtimeInputs = [ script ];
    text = ''
      NOTIFY_EXE=${lib.getExe script}
      ${builtins.readFile ./agent-prompt.sh}
    '';
  };

  sessionsScript = pkgs.sysinit.writeShellApplication {
    name = "agent-sessions";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.wezterm
      pkgs.seshy
    ];
    bashOptions = [ ];
    text = joinFragments [
      paths
      (builtins.replaceStrings [ "@agentSessionsReducer@" ] [ "${./agent-sessions.jq}" ] (
        builtins.readFile ./agent-sessions.sh
      ))
    ];
  };

  reviewScript = pkgs.sysinit.writeShellApplication {
    name = "agent-review";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.wezterm
    ];
    text = joinFragments [
      paths
      busyPanes
      (builtins.readFile ./agent-review.sh)
    ];
  };

  specPreflight = pkgs.sysinit.writeShellApplication {
    name = "spec-preflight";
    runtimeInputs = [
      pkgs.citelock
      pkgs.coreutils
      pkgs.git
      pkgs.gnugrep
      pkgs.gnused
      pkgs.findutils
      pkgs.ripgrep
    ];
    text = builtins.readFile ./spec-preflight.sh;
  };

  agentRefine = pkgs.sysinit.writeShellApplication {
    name = "agent-refine";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.findutils
      pkgs.gnugrep
    ];
    text = joinFragments [
      paths
      (builtins.readFile ./agent-refine.sh)
    ];
  };

  focusScript = pkgs.sysinit.writeShellApplication {
    name = "agent-focus";
    runtimeInputs = [
      pkgs.wezterm
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    text = joinFragments [
      group
      (builtins.readFile (pkgs.agent-signals-source + "/runtime/agent-focus.sh"))
    ];
  };
in
{
  inherit
    icons
    script
    promptScript
    focusScript
    reviewScript
    sessionsScript
    agentRefine
    specPreflight
    ;

  inherit (script) configFile schema;
  assetManifest = pkgs.writeText "agent-notify-assets.json" (
    builtins.toJSON {
      version = "agent-notify-assets/v1";
      size = 256;
      background = "#FFFFFF";
      icons = lib.mapAttrs (name: source: {
        inherit source;
        rendered = "${icons}/${name}.png";
      }) svgs;
    }
  );

  iconFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair "agent-notify/icons/${name}.png" {
        source = "${icons}/${name}.png";
      }
    ) (builtins.attrNames svgs)
  );
}
