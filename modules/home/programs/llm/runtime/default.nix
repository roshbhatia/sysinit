# Agent-agnostic desktop notifier shared by every harness's lifecycle hooks.
# Icons rasterise to 256px on a white tile so a mono-colour glyph stays legible
# in both light and dark notification chrome.
{
  pkgs,
  lib,
}:
let
  # Vendored, not fetched. These were `fetchurl` against cdn.simpleicons.org,
  # which now answers 403 to GitHub's runners while serving everyone else, so
  # every cold CI build failed on a third party's willingness to serve us. An
  # icon is static by definition and there is nothing to gain from refetching it
  # on each build. `hack/update-agent-icons.sh` refreshes them deliberately and
  # shows the drift; nothing updates them automatically.
  icon = name: ./icons/${name}.svg;

  svgs = {
    claude = icon "claude";
    codex = icon "codex";
    gemini = icon "gemini";
    cursor = icon "cursor";
    opencode = icon "opencode";
    # simpleicons "Pi" sources from pi.dev, so it is the agent, not Pi Network
    pi = icon "pi";
    copilot = icon "copilot";
  };

  # Reaches agent-notify directly, carrying a reason string. Via the harness's
  # own hooks, or via a bridge under harnesses/{pi,opencode}/.
  hookBridged = [
    "claude"
    "codex"
    "pi"
    "opencode"
  ];

  # Reaches agent-notify via the agent-deck scrape bridge in ui.lua. Carries a
  # status but no reason, so its toasts are less specific.
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

  # keyed on the bridge file, not the label: the label lives here too, so a
  # contributor removing a bridge would edit both and the guard would agree
  bridgeArtifacts = {
    pi = ../harnesses/pi/extensions/sysinit-notify.ts;
    opencode = ../harnesses/opencode/plugins/sysinit-notify.ts;
  };

  # a zero-byte file passes `pathExists` but loads no handlers
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

  # No correct brand asset, so they render the generic glyph. simpleicons "AMP"
  # is Google Accelerated Mobile Pages, not Sourcegraph Amp; crush and goose
  # have no entry at all.
  intentionallyGeneric = [
    "amp"
    "crush"
    "goose"
    "devin"
  ];

  # authored, not fetched: the fallback must not resemble any harness glyph
  genericSvg = pkgs.writeText "agent-icon-generic.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
      <circle cx="12" cy="12" r="9" fill="none" stroke="#6E7781" stroke-width="2"
              stroke-dasharray="3 2.5" stroke-linecap="round"/>
      <circle cx="12" cy="12" r="3" fill="#6E7781"/>
    </svg>
  '';

  names = builtins.attrNames svgs;

  # forced from `icons` below: an unreferenced `let` binding is dropped silently
  genericConflicts = lib.intersectLists names intentionallyGeneric;
  assertGenericDisjoint =
    if genericConflicts != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " genericConflicts} appear in both `svgs` and `intentionallyGeneric`; a harness cannot be both."
    else
      "";

  # prepended into both scripts at build time so they cannot disagree
  identity = builtins.readFile ./agent-identity.sh;

  # kept separate from `identity`: agent-focus needs the group and nothing else
  group = builtins.readFile ./agent-group.sh;

  # The review-path suffix a done toast carries. Prepended into the notifier and
  # read by the notify-defect-regressions check, so the shipped body and the
  # asserted body are the same code.
  reviewSuffix = builtins.readFile ./agent-review-suffix.sh;

  # Which panes of a session still hold a non-idle agent state. Prepended into the
  # report and read by the agent-review-readiness check, so the gate and the
  # assertion run the same intersection.
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
    # best-effort: no errexit, it must never abort the agent
    bashOptions = [ ];
    text = group + "\n" + reviewSuffix + "\n" + identity + "\n" + builtins.readFile ./agent-notify.sh;
  };

  # Per-pane lifecycle-state emitter (see agent-state.sh). Writes an OSC 1337
  # SetUserVar to the agent's wezterm pane so the statusline/switcher can show
  # which session is blocked and why. Best-effort, like the notifier.
  stateScript = pkgs.writeShellApplication {
    name = "agent-state";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.wezterm
    ];
    bashOptions = [ ];
    text = identity + "\n" + builtins.readFile ./agent-state.sh;
  };

  # Approval notifier: alerter Accept/Deny relayed back into the agent pane.
  # alerter is darwin-only, so elsewhere `command -v` misses and the plain
  # notifier fires instead.
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

  # The session rollup as JSON, for a status bar (see agent-sessions.sh). Always
  # exits 0: a bar polls it, so a non-zero exit for the idle case would make every
  # bar render an error as its steady state.
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

  # Session readiness report (see agent-review.sh). Read-only by contract.
  reviewScript = pkgs.writeShellApplication {
    name = "agent-review";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.wezterm
    ];
    # unlike the notifier, its exit code is the gate, so strict mode stays on
    text = busyPanes + "\n" + builtins.readFile ./agent-review.sh;
  };

  # `sy delete` gate (see sy-gate.sh), named `sy` so it shadows seshy on PATH.
  # Evaluates a declared STOP condition as a Stop hook. Disarmed by default, so
  # an ordinary session is unaffected. See runtime/loop-gate.sh.
  loopGate = pkgs.writeShellApplication {
    name = "loop-gate";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
    ];
    text = builtins.readFile ./loop-gate.sh;
  };

  # Agent review notes on a working-tree diff (see diffnote.sh). Writes JSON;
  # neovim's CodeDiff view watches that file and renders it.
  diffNote = pkgs.writeShellApplication {
    name = "diffnote";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
      pkgs.gnused
    ];
    text = builtins.readFile ./diffnote.sh;
  };

  # The deterministic half of the spec-driven authoring rules (see
  # spec-preflight.sh). The schema instructions call it instead of restating what
  # it checks.
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

  # Periodic refinement of the durable half of the harness (see agent-refine.sh).
  # Proposes; never applies.
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
    # fzf so the gate can run the picker itself for a bare `sy delete`; without it
    # that form execs through and the readiness check never sees the pick.
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

  # Click handler. Runs in a bare NotificationCenter env, so every binary must
  # come from runtimeInputs rather than an inherited PATH.
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
    diffNote
    agentRefine
    specPreflight
    ;

  # Absolute paths used inside harness hook commands.
  exe = lib.getExe script;
  stateExe = lib.getExe stateScript;
  promptExe = lib.getExe promptScript;
  focusExe = lib.getExe focusScript;
  reviewExe = lib.getExe reviewScript;
  sessionsExe = lib.getExe sessionsScript;
  diffNoteExe = lib.getExe diffNote;

  # wired once in default.nix to avoid a home.file collision
  iconFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".local/share/agent-notify/icons/${name}.png" {
        source = "${icons}/${name}.png";
      }
    ) (names ++ [ "agent" ])
  );
}
