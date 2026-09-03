{
  pkgs,
  lib,
}:
let
  registry = import ../harnesses/registry.nix;

  svgs = builtins.mapAttrs (name: _h: ./icons/${name}.svg) (
    lib.filterAttrs (_name: h: h.ownIcon) registry
  );

  genericSvg = pkgs.writeText "agent-icon-generic.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
      <circle cx="12" cy="12" r="9" fill="none" stroke="#6E7781" stroke-width="2"
              stroke-dasharray="3 2.5" stroke-linecap="round"/>
      <circle cx="12" cy="12" r="3" fill="#6E7781"/>
    </svg>
  '';

  labels = ''
    agent_label() {
      case "$1" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: h: "    ${name}) printf '%s\\n' ${lib.escapeShellArg h.label} ;;"
      ) registry
    )}
        *) printf '%s\n' "$1" ;;
      esac
    }
  '';

  paths = builtins.readFile ./paths.sh;

  identity = builtins.readFile ./agent-identity.sh;

  group = builtins.readFile ./agent-group.sh;

  reviewSuffix = builtins.readFile ./agent-review-suffix.sh;

  busyPanes = builtins.readFile ./agent-busy-panes.sh;

  classify = builtins.readFile ./agent-classify.sh;

  joinFragments = lib.concatStringsSep "\n";

  iconCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: src:
      "rsvg-convert --width 256 --height 256 --keep-aspect-ratio --background-color '#FFFFFF' '${src}' --output \"$out/${name}.png\""
    ) svgs
  );

  icons = pkgs.runCommand "agent-notify-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
    mkdir -p "$out"
    ${iconCommands}
    rsvg-convert --width 256 --height 256 --keep-aspect-ratio \
      --background-color '#FFFFFF' '${genericSvg}' --output "$out/agent.png"
  '';

  script = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.wezterm
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    text = joinFragments [
      paths
      group
      reviewSuffix
      identity
      labels
      classify
      (builtins.readFile ./agent-notify.sh)
    ];
  };

  promptScript = pkgs.writeShellApplication {
    name = "agent-prompt";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.wezterm
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    text = joinFragments [
      ''
        NOTIFY_EXE=${lib.getExe script}
      ''
      paths
      group
      identity
      labels
      classify
      (builtins.readFile ./agent-prompt.sh)
    ];
  };

  sessionsScript = pkgs.writeShellApplication {
    name = "agent-sessions";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
      pkgs.wezterm
      pkgs.seshy
    ];
    bashOptions = [ ];
    text = joinFragments [
      paths
      (builtins.readFile ./agent-sessions.sh)
    ];
  };

  reviewScript = pkgs.writeShellApplication {
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

  specPreflight = pkgs.writeShellApplication {
    name = "spec-preflight";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.gnugrep
      pkgs.gnused
      pkgs.gawk
      pkgs.findutils
      pkgs.ripgrep
    ];
    text = builtins.readFile ./spec-preflight.sh;
  };

  agentRefine = pkgs.writeShellApplication {
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

  syGate = pkgs.writeShellApplication {
    name = "sy";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fzf
    ];
    text = joinFragments [
      ''
        SY_REAL=${lib.getExe' pkgs.seshy "sy"}
      ''
      paths
      (builtins.readFile ./sy-gate.sh)
    ];
  };

  focusScript = pkgs.writeShellApplication {
    name = "agent-focus";
    runtimeInputs = [
      pkgs.wezterm
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    text = joinFragments [
      group
      (builtins.readFile ./agent-focus.sh)
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
    syGate
    agentRefine
    specPreflight
    ;

  iconFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".local/share/agent-notify/icons/${name}.png" {
        source = "${icons}/${name}.png";
      }
    ) (builtins.attrNames svgs ++ [ "agent" ])
  );
}
