{
  pkgs,
  lib,
}:
let
  icon = name: ./icons/${name}.svg;

  svgs = {
    claude = icon "claude";
    codex = icon "codex";
    gemini = icon "gemini";
    cursor = icon "cursor";
    opencode = icon "opencode";
    pi = icon "pi";
    copilot = icon "copilot";
  };

  hookBridged = [
    "claude"
    "codex"
    "pi"
    "opencode"
  ];

  scrapeBridged = [
    "amp"
    "copilot"
    "crush"
    "cursor"
    "devin"
    "gemini"
    "goose"
  ];

  configuredHarnesses = [
    "amp"
    "claude"
    "codex"
    "copilot"
    "crush"
    "cursor"
    "devin"
    "gemini"
    "goose"
    "opencode"
    "pi"
  ];

  covered = hookBridged ++ scrapeBridged;

  bridgeArtifacts = {
    pi = ../harnesses/pi/extensions/sysinit-notify.ts;
    opencode = ../harnesses/opencode/plugins/sysinit-notify.ts;
  };

  bridgePresent = p: builtins.pathExists p && builtins.stringLength (builtins.readFile p) > 0;

  missingBridges = lib.filter (
    h: (bridgeArtifacts ? ${h}) && !(bridgePresent bridgeArtifacts.${h})
  ) hookBridged;

  assertBridgesExist =
    if missingBridges != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " missingBridges} is listed as bridged but its bridge file is missing. Its own producer is off, so it would have no notifier at all."
    else
      "";

  uncovered = lib.subtractLists covered configuredHarnesses;
  stale = lib.subtractLists configuredHarnesses covered;

  assertCoverageTotal =
    if uncovered != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " uncovered} configured but reaches no notifier. Add each to hookBridged or scrapeBridged."
    else if stale != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " stale} named as covered but not configured. Remove the stale entry."
    else
      "";

  intentionallyGeneric = [
    "amp"
    "crush"
    "goose"
    "devin"
  ];

  genericSvg = pkgs.writeText "agent-icon-generic.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
      <circle cx="12" cy="12" r="9" fill="none" stroke="#6E7781" stroke-width="2"
              stroke-dasharray="3 2.5" stroke-linecap="round"/>
      <circle cx="12" cy="12" r="3" fill="#6E7781"/>
    </svg>
  '';

  names = builtins.attrNames svgs;

  genericConflicts = lib.intersectLists names intentionallyGeneric;
  assertGenericDisjoint =
    if genericConflicts != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " genericConflicts} appear in both `svgs` and `intentionallyGeneric`; a harness cannot be both."
    else
      "";

  identity = builtins.readFile ./agent-identity.sh;

  group = builtins.readFile ./agent-group.sh;

  reviewSuffix = builtins.readFile ./agent-review-suffix.sh;

  busyPanes = builtins.readFile ./agent-busy-panes.sh;

  icons = pkgs.runCommand "agent-notify-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } (
    assertGenericDisjoint
    + assertCoverageTotal
    + assertBridgesExist
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
    text = group + "\n" + reviewSuffix + "\n" + identity + "\n" + builtins.readFile ./agent-notify.sh;
  };

  stateScript = pkgs.writeShellApplication {
    name = "agent-state";
    runtimeInputs = [
      pkgs.git
      pkgs.sysinit-agent
      pkgs.wezterm
    ];
    bashOptions = [ ];
    text = ''
      exec sysinit-agent agent-state "$@"
    '';
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
    + group
    + "\n"
    + identity
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
    text = builtins.readFile ./agent-sessions.sh;
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
    text = busyPanes + "\n" + builtins.readFile ./agent-review.sh;
  };

  loopGate = pkgs.writeShellApplication {
    name = "loop-gate";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
    ];
    text = builtins.readFile ./loop-gate.sh;
  };

  # The reader half. `hunk` itself stays on PATH under its own name; this only
  # adds the repository's note export to it.
  noteReview = pkgs.writeShellApplication {
    name = "review";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.hunk
      pkgs.sysinit-agent
    ];
    text = builtins.readFile ./review.sh;
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
    text = builtins.readFile ./agent-refine.sh;
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
    stateScript
    promptScript
    focusScript
    loopGate
    reviewScript
    sessionsScript
    syGate
    noteReview
    agentRefine
    specPreflight
    ;

  exe = lib.getExe script;
  stateExe = lib.getExe stateScript;
  promptExe = lib.getExe promptScript;
  focusExe = lib.getExe focusScript;
  reviewExe = lib.getExe reviewScript;
  sessionsExe = lib.getExe sessionsScript;
  noteReviewExe = lib.getExe noteReview;

  iconFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".local/share/agent-notify/icons/${name}.png" {
        source = "${icons}/${name}.png";
      }
    ) (names ++ [ "agent" ])
  );
}
