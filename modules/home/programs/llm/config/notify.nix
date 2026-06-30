# Agent-agnostic desktop notifier shared by every harness's lifecycle hooks.
#
# Builds two things and exposes them for the per-harness configs to wire in:
#   - icons : per-agent app icons, fetched (not vendored) and rendered to PNG
#   - exe   : absolute path to the `agent-notify` script (see agent-notify.sh)
#
# Icons are SVGs pulled from upstream brand sources, pinned by hash, and rasterised
# to 256px PNGs on a white tile so a mono-colour glyph stays legible in both light
# and dark notification chrome. They install to ~/.local/share/agent-notify/icons.
{ pkgs, lib }:
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
    aider =
      icon "aider" "https://aider.chat/assets/logo.svg"
        "sha256-wgEroKMUHvFi9rxvTMjLSrGURNugQIyXX1jO7aTtebE=";
  };

  names = builtins.attrNames svgs;

  icons = pkgs.runCommand "agent-notify-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } (
    "mkdir -p $out\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: src:
        "rsvg-convert --width 256 --height 256 --keep-aspect-ratio --background-color '#FFFFFF' '${src}' --output \"$out/${name}.png\""
      ) svgs
    )
    # Generic fallback icon for any agent without a dedicated glyph.
    + "\ncp \"$out/claude.png\" \"$out/agent.png\"\n"
  );

  script = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.terminal-notifier
      pkgs.wezterm
    ];
    # Best-effort notifier: no errexit/nounset/pipefail — it must never abort the
    # agent. shellcheck still runs for validation.
    bashOptions = [ ];
    text = builtins.readFile ./agent-notify.sh;
  };

  # Per-pane lifecycle-state emitter (see agent-state.sh). Writes an OSC 1337
  # SetUserVar to the agent's wezterm pane so the statusline/switcher can show
  # which session is blocked and why. Best-effort, like the notifier.
  stateScript = pkgs.writeShellApplication {
    name = "agent-state";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    bashOptions = [ ];
    text = builtins.readFile ./agent-state.sh;
  };

  # Notification click handler: raises the wezterm pane the agent runs in. Runs in
  # a bare NotificationCenter env, so wezterm/jq must come from runtimeInputs, not
  # an inherited PATH.
  focusScript = pkgs.writeShellApplication {
    name = "agent-focus";
    runtimeInputs = [
      pkgs.wezterm
      pkgs.jq
    ];
    bashOptions = [ ];
    text = builtins.readFile ./agent-focus.sh;
  };
in
{
  inherit icons script stateScript focusScript;

  # Absolute paths used inside harness hook commands.
  exe = lib.getExe script;
  stateExe = lib.getExe stateScript;
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
