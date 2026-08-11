{
  pkgs,
  lib,
}:
let
  # Every harness fact here comes from the registry, so the four assertions that
  registry = import ../harnesses/registry.nix;

  svgs = builtins.mapAttrs (name: _h: ./icons/${name}.svg) (
    lib.filterAttrs (_name: h: h.ownIcon) registry
  );

  bridgeArtifacts = lib.filterAttrs (_name: v: v != null) (
    builtins.mapAttrs (_name: h: h.bridge) registry
  );

  bridgePresent = p: builtins.pathExists p && builtins.stringLength (builtins.readFile p) > 0;

  # The one property the registry cannot make unrepresentable: a declared bridge whose
  # file is empty or absent leaves that harness with no notifier at all.
  missingBridges = builtins.attrNames (
    lib.filterAttrs (_name: src: !(bridgePresent src)) bridgeArtifacts
  );

  assertBridgesExist =
    if missingBridges != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " missingBridges} declares a notify bridge whose file is missing or empty. Its own producer is off, so it would have no notifier at all."
    else
      "";

  # `neovimAdapter` is declared on every entry and read by no Nix code, so
  # nothing but this check stops an entry naming an adapter that was never
  # written. `harness/registry.lua` requires each adapter under `pcall`, so the
  # runtime failure is a silent skip: the harness just never appears.
  adapterDir = ../../neovim/config/lua/harness/adapters;

  missingAdapters = lib.mapAttrsToList (_name: h: h.neovimAdapter) (
    lib.filterAttrs (_name: h: !(builtins.pathExists (adapterDir + "/${h.neovimAdapter}.lua"))) registry
  );

  assertNeovimAdaptersExist =
    if missingAdapters != [ ] then
      throw "runtime/default.nix: ${lib.concatStringsSep ", " missingAdapters} is named by a registry neovimAdapter but no such file exists under neovim/config/lua/harness/adapters. registry.lua would skip it silently."
    else
      "";

  # `editBus` is read by no Nix code either, and the one way to get it wrong is to
  # claim it on a harness that has no hook surface to write from. That entry would
  # look supported and emit nothing.
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

  # Generated from the registry rather than written twice.
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

  # Prepended wherever a script needs a state path, so no script composes one.
  paths = builtins.readFile ./paths.sh;

  identity = builtins.readFile ./agent-identity.sh;

  group = builtins.readFile ./agent-group.sh;

  reviewSuffix = builtins.readFile ./agent-review-suffix.sh;

  busyPanes = builtins.readFile ./agent-busy-panes.sh;

  icons = pkgs.runCommand "agent-notify-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } (
    assertBridgesExist
    + assertNeovimAdaptersExist
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

  # Named for what it records rather than for the harness, because the harness
  # name is an argument and every hook-capable harness calls the same command.
  editEventScript = pkgs.writeShellApplication {
    name = "agent-edit-event";
    runtimeInputs = [
      pkgs.git
      pkgs.sysinit-agent
    ];
    bashOptions = [ ];
    text = ''
      exec sysinit-agent edit-event "$@"
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

  loopGate = pkgs.writeShellApplication {
    name = "loop-gate";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
    ];
    text = builtins.readFile ./loop-gate.sh;
  };

  # The reader half.
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
    stateScript
    editEventScript
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
  editEventExe = lib.getExe editEventScript;
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
    ) (builtins.attrNames svgs ++ [ "agent" ])
  );
}
