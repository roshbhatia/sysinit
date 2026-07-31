# Agent-agnostic desktop notifier shared by every harness's lifecycle hooks.
#
# Builds two things and exposes them for the per-harness configs to wire in:
#   - icons : per-agent app icons, fetched (not vendored) and rendered to PNG
#   - exe   : absolute path to the `agent-notify` script (see agent-notify.sh)
#
# Icons are SVGs pulled from upstream brand sources, pinned by hash, and rasterised
# to 256px PNGs on a white tile so a mono-colour glyph stays legible in both light
# and dark notification chrome. They install to ~/.local/share/agent-notify/icons.
{
  pkgs,
  lib,
}:
let
  icon =
    name: url: hash:
    pkgs.fetchurl {
      inherit url hash;
      name = "agent-icon-${name}.svg";
    };

  # url + pinned sha256 per source. Hashes drift only if upstream changes the
  # asset, in which case the build fails loudly rather than shipping a stale icon.
  svgs = {
    claude =
      icon "claude" "https://cdn.simpleicons.org/claude/D97757"
        "sha256-URnvlQoNZIs/1ihleR5z8H8y4Y3auE5PIRYPjGQcD18=";
    codex =
      icon "codex" "https://upload.wikimedia.org/wikipedia/commons/0/04/ChatGPT_logo.svg"
        "sha256-Wo2tKGTMHIEJ6650vqRH3y8wuXi9rVZ0kkfEBuHLIic=";
    gemini =
      icon "gemini" "https://cdn.simpleicons.org/googlegemini/4285F4"
        "sha256-GKkvBO7dgQklPx29NxQhGTqZEhAGdFZ2lFurnRLeMPk=";
    cursor =
      icon "cursor" "https://cdn.simpleicons.org/cursor/000000"
        "sha256-aMiOMXoD/vt9jtaLn+hu8zwKACdl+mv8hM3EPXu59P4=";
    opencode =
      icon "opencode" "https://cdn.simpleicons.org/opencode/000000"
        "sha256-xlr+/bHrZ74ZpQ9xXQp6LBlVjb8Mvcl0/rNn4FXNX1g=";
    # simpleicons "Pi" sources from https://pi.dev/favicon.svg, which is the
    # coding agent's own vendor domain, not Pi Network. Verified before use.
    pi =
      icon "pi" "https://cdn.simpleicons.org/pi/000000"
        "sha256-0462udrr6XCPzGCuF9Ue7bnx5lZhyVytXC4eJzt3vyE=";
    copilot =
      icon "copilot" "https://cdn.simpleicons.org/githubcopilot/000000"
        "sha256-DTSwqoKcIwlOr84UR0gdVvQd3mXXeRISItzylJQ90kU=";
  };

  # Notification coverage for every harness this repository configures. Each
  # name sits in exactly one list, and a configured harness in neither fails the
  # build below. agent-notify is the only producer either path reaches.
  #
  # Reaches agent-notify directly, carrying a reason string, so its toasts name
  # the tool and its input. Either from the harness's own lifecycle hooks, or
  # from a repository-authored bridge where the harness has no hooks.
  hookBridged = [
    "claude"
    "codex"
    # Reached through repository-authored bridges rather than hooks, but on the
    # same footing: both call agent-notify directly and carry a reason string.
    # pi uses an extension, opencode a plugin; see config/extensions/ and
    # config/plugins/sysinit-notify.ts.
    "pi"
    "opencode"
  ];

  # Reaches agent-notify from the agent-deck scrape bridge in ui.lua. agent-deck
  # detects these by process, argv, and title pattern, and the bridge forwards
  # the transition. This path carries a status but no reason, so its toasts are
  # less specific than the hook path. A pane that emits its own agent_state is
  # skipped by the bridge, so a hook-bridged harness is never announced twice.
  scrapeBridged = [
    "amp"
    "copilot"
    "crush"
    "cursor"
    "devin"
    "gemini"
    "goose"
  ];

  # Every harness config imported by default.nix. Compared against the coverage
  # set below, so adding a harness without classifying it fails the build rather
  # than silently shipping a harness nothing notifies for.
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

  # Turning a harness's own producer off is only safe once its bridge exists.
  # Key on the bridge FILE, not on the coverage label: the label lives in this
  # same file, so a contributor removing a bridge would edit both and the guard
  # would agree with them.
  bridgeArtifacts = {
    pi = ./extensions/sysinit-notify.ts;
    opencode = ./plugins/sysinit-notify.ts;
  };

  # A zero-byte file passes `pathExists` and loads as a module with no handlers,
  # which is indistinguishable from having no bridge at all.
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

  # Harnesses with no correct brand asset. They render the generic glyph, which
  # is visually distinct from every entry in `svgs` above, so an unrecognized
  # agent is never mistaken for a recognized one.
  #
  # amp is listed here deliberately: simpleicons ships an "AMP" icon, but its
  # source is https://amp.dev, which is Google's Accelerated Mobile Pages, not
  # Sourcegraph Amp. Shipping it would put a wrong brand on the toast.
  # crush and goose have no simpleicons entry at all.
  intentionallyGeneric = [
    "amp"
    "crush"
    "goose"
    "devin"
  ];

  # Authored here rather than fetched: the fallback must not resemble any
  # harness glyph, and no upstream asset guarantees that. A dashed ring with a
  # centre dot reads as "an agent we do not recognize" at 256px.
  genericSvg = pkgs.writeText "agent-icon-generic.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
      <circle cx="12" cy="12" r="9" fill="none" stroke="#6E7781" stroke-width="2"
              stroke-dasharray="3 2.5" stroke-linecap="round"/>
      <circle cx="12" cy="12" r="3" fill="#6E7781"/>
    </svg>
  '';

  names = builtins.attrNames svgs;

  # `intentionallyGeneric` must stay a mechanism, not a comment. A name in both
  # lists means someone added a real glyph and forgot to drop the generic
  # record, so the file would claim a harness is generic while shipping its
  # icon. Forced from `icons` below, because an unreferenced `let` binding is
  # dropped silently and never fires (the defect this repo already carries at
  # config/pi.nix:491).
  genericConflicts = lib.intersectLists names intentionallyGeneric;
  assertGenericDisjoint =
    if genericConflicts != [ ] then
      throw "notify.nix: ${lib.concatStringsSep ", " genericConflicts} appear in both `svgs` and `intentionallyGeneric`; a harness cannot be both."
    else
      "";

  # Shared session/repo/pane identity resolution, prepended into both scripts at
  # build time so agent-notify and agent-state can never disagree (no runtime
  # source path to resolve, and shellcheck validates the combined script).
  identity = builtins.readFile ./agent-identity.sh;

  # The notification group name, shared by both producers and by the click
  # handler (see agent-group.sh). Kept separate from `identity` because
  # agent-focus needs the group function and none of the identity resolution.
  group = builtins.readFile ./agent-group.sh;

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
    # Generic fallback for any agent without a dedicated glyph. Rendered from
    # the authored SVG above, NOT copied from claude.png as it once was: a copy
    # made every unrecognized agent render as Claude.
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
    # Best-effort notifier: no errexit/nounset/pipefail — it must never abort the
    # agent. shellcheck still runs for validation.
    bashOptions = [ ];
    text = group + "\n" + identity + "\n" + builtins.readFile ./agent-notify.sh;
  };

  # Per-pane lifecycle-state emitter (see agent-state.sh). Writes an OSC 1337
  # SetUserVar to the agent's wezterm pane so the statusline/switcher can show
  # which session is blocked and why. Best-effort, like the notifier.
  stateScript = pkgs.writeShellApplication {
    name = "agent-state";
    # git + wezterm are needed by the shared identity resolver for the state-file
    # transport (repo/branch/dirty derivation, workspace lookup); jq builds the
    # JSON payload with correct escaping.
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.wezterm
    ];
    bashOptions = [ ];
    text = identity + "\n" + builtins.readFile ./agent-state.sh;
  };

  # Actionable permission notifier (see agent-prompt.sh). For genuine approval
  # events it shows an `alerter` Accept/Deny notification and relays the choice
  # back into the agent pane; otherwise it degrades to the plain agent-notify
  # toast. alerter is darwin-only + optional, so it is added to PATH only on
  # darwin — elsewhere `command -v alerter` misses and the fallback fires.
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
    # Preamble bakes the fallback notifier path; then the shared identity
    # resolver; then the script body — one combined unit so shellcheck validates
    # it whole.
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

  # Notification click handler: raises the wezterm pane the agent runs in. Runs in
  # a bare NotificationCenter env, so wezterm/jq must come from runtimeInputs, not
  # an inherited PATH.
  focusScript = pkgs.writeShellApplication {
    name = "agent-focus";
    # alerter dismisses the originating toast (`--remove <group>`); darwin-only,
    # so the script's `command -v alerter` gate covers every other platform.
    runtimeInputs = [
      pkgs.wezterm
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.alerter ];
    bashOptions = [ ];
    # The group helper is prepended so agent-focus rebuilds the notification
    # group with the same `agent_group` the producers used. A second copy of
    # that string is what let the dismiss silently miss.
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
    ;

  # Absolute paths used inside harness hook commands.
  exe = lib.getExe script;
  stateExe = lib.getExe stateScript;
  promptExe = lib.getExe promptScript;
  focusExe = lib.getExe focusScript;

  # home.file entries installing every icon (plus the fallback) to the shared
  # location the script reads from. Wired once in default.nix to avoid collisions.
  iconFiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair ".local/share/agent-notify/icons/${name}.png" {
        source = "${icons}/${name}.png";
      }
    ) (names ++ [ "agent" ])
  );
}
