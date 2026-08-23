{
  pkgs,
  lib,
}:
let
  registry = import ../harnesses/registry.nix;

  svgs = builtins.mapAttrs (name: _h: ./icons/${name}.svg) (
    lib.filterAttrs (_name: h: h.ownIcon) registry
  );

  bridgeArtifacts = lib.filterAttrs (_name: v: v != null) (
    builtins.mapAttrs (_name: h: h.bridge) registry
  );

  bridgePresent = p: builtins.pathExists p && builtins.stringLength (builtins.readFile p) > 0;

  missingBridges = builtins.attrNames (
    lib.filterAttrs (_name: src: !(bridgePresent src)) bridgeArtifacts
  );

  assertBridgesExist =
    if missingBridges != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " missingBridges} declares a notify bridge whose file is missing or empty. Its own producer is off, so it would have no notifier at all."
    else
      "";

  commandless = builtins.attrNames (
    lib.filterAttrs (_name: h: h.command == null || h.command == "") registry
  );

  assertCommandsNamed =
    if commandless != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " commandless} names no command, so agents.json would offer a launch entry that runs nothing."
    else
      "";

  # Every acp = true harness must have an entry in lib/acp.nix, or agents.json
  # advertises an ACP capability with no server behind it.
  acpServers = builtins.attrNames (import ../lib/acp.nix { inherit lib; }).servers;

  acpWithoutServer = builtins.attrNames (
    lib.filterAttrs (name: h: h.acp && !(builtins.elem name acpServers)) registry
  );

  assertAcpServersExist =
    if acpWithoutServer != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " acpWithoutServer} sets acp but lib/acp.nix declares no server for it."
    else
      "";

  # The deck is the only status source a "scrape" harness has, so a missing entry
  # leaves it with no status on any channel and nothing says so. hermes shipped
  # that way.
  deckPatterns = import ../harnesses/deck-patterns.nix;

  undecked = builtins.attrNames (lib.filterAttrs (name: _h: !(deckPatterns ? ${name})) registry);

  strayDeck = builtins.filter (name: !(registry ? ${name})) (builtins.attrNames deckPatterns);

  emptyDeck = builtins.attrNames (
    lib.filterAttrs (_name: p: p.patterns == [ ] || p.executable_patterns == [ ]) deckPatterns
  );

  assertDeckCoversRegistry =
    if undecked != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " undecked} has no entry in harnesses/deck-patterns.nix, so the wezterm deck cannot recognise it in a pane."
    else if strayDeck != [ ] then
      throw "runtime/default.nix: harnesses/deck-patterns.nix names ${lib.concatStringsSep ", " strayDeck}, which the harness registry does not."
    else if emptyDeck != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " emptyDeck} declares empty deck patterns, which match nothing."
    else
      "";

  busWithoutHook = builtins.attrNames (
    lib.filterAttrs (_name: h: h.editBus && h.notify != "hook") registry
  );

  assertBusHarnessesHook =
    if busWithoutHook != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " busWithoutHook} sets editBus but notify is not \"hook\", so it has no hook surface to write edit events from."
    else
      "";

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

  icons = pkgs.runCommand "agent-notify-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } (
    assertBridgesExist
    + assertCommandsNamed
    + assertAcpServersExist
    + assertDeckCoversRegistry
    + assertBusHarnessesHook
    + "mkdir -p $out\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: src:
        "rsvg-convert --width 256 --height 256 --keep-aspect-ratio --background-color '#FFFFFF' '${src}' --output \"$out/${name}.png\""
      ) svgs
    )
    + "\nrsvg-convert --width 256 --height 256 --keep-aspect-ratio --background-color '#FFFFFF' '${genericSvg}' --output \"$out/agent.png\"\n"
  );

  script = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.alerter
      pkgs.wezterm
    ];
    bashOptions = [ ];
    text =
      paths
      + "\n"
      + group
      + "\n"
      + reviewSuffix
      + "\n"
      + identity
      + "\n"
      + labels
      + "\n"
      + builtins.readFile ./agent-notify.sh;
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
    text = ''
      NOTIFY_EXE=${lib.getExe script}
    ''
    + "\n"
    + paths
    + "\n"
    + group
    + "\n"
    + identity
    + "\n"
    + labels
    + "\n"
    + builtins.readFile ./agent-prompt.sh;
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
    text = paths + "\n" + builtins.readFile ./agent-sessions.sh;
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
    text = paths + "\n" + busyPanes + "\n" + builtins.readFile ./agent-review.sh;
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
    text = paths + "\n" + builtins.readFile ./agent-refine.sh;
  };

  syGate = pkgs.writeShellApplication {
    name = "sy";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fzf
    ];
    text = ''
      SY_REAL=${lib.getExe' pkgs.seshy "sy"}
    ''
    + "\n"
    + paths
    + "\n"
    + builtins.readFile ./sy-gate.sh;
  };

  focusScript = pkgs.writeShellApplication {
    name = "agent-focus";
    runtimeInputs = [
      pkgs.wezterm
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    text = group + "\n" + builtins.readFile ./agent-focus.sh;
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
