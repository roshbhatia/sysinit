{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # `formatForGoose` returns `{ shell = { allow = [...]; deny = []; } }` which
  # must be merged at the top level with `//` — assigning it to a `shell` key
  # would produce double nesting (`shell.shell.allow`) that goose would ignore.
  # tierA allow-list, plus the shared destructive-command patterns as
  # `shell.deny` regexes (goose matches shell.deny as regex). formatForGoose
  # emits `deny = []`; override it here so goose blocks the same forms as the
  # other harnesses.
  gooseShell = llmLib.allowlist.formatForGoose llmLib.allowlist.tierA;
  gooseShellWithDeny = {
    shell = gooseShell.shell // {
      deny = llmLib.allowlist.formatDestructiveForGoose llmLib.allowlist.destructiveDenyRegexes;
    };
  };

  gooseConfig = builtins.toJSON (
    {
      EDIT_MODE = "vi";
      GOOSE_CLI_MIN_PRIORITY = 0.2;
      GOOSE_CLI_THEME = "ansi";
      # Risk-assessed approval instead of blanket auto: goose prompts on
      # higher-risk actions, auto-runs the rest.
      GOOSE_MODE = "smart_approve";
      GOOSE_TOOLSHIM = true;

      extensions = llmLib.mcp.formatForGoose kit.mcpServers.servers;
    }
    // gooseShellWithDeny
  );

  # Goose's runtime wants to mutate this file (e.g., when the user
  # answers the first-run telemetry prompt). xdg.configFile would symlink
  # it from the read-only nix store, and goose then fails with
  # "Too many symlink levels (or a cycle)" while trying to rewrite.
  # We materialize a writable copy via home.activation instead, mirroring
  # the updatePiSettings pattern from pi.nix.
  gooseConfigBase = pkgs.writeText "goose-config-base.json" gooseConfig;

  updateGooseConfig = pkgs.writeShellScript "update-goose-config" ''
    set -euo pipefail

    target="$HOME/.config/goose/config.yaml"
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    # If the existing file is a symlink (left over from the old
    # xdg.configFile setup), replace it outright. Otherwise deep-merge
    # any keys goose has added at runtime (telemetry, etc.) with our
    # nix-managed base.
    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    merged="$(mktemp "''${target}.tmp.XXXXXX")"
    trap 'rm -f "$merged"' EXIT

    if [ -f "$target" ]; then
      # yq (mikefarah/yq) handles both JSON and YAML input. eval-all reads
      # every doc and ireduce merges them; the later doc (our nix base)
      # wins on conflict for canonical fields, while goose's runtime
      # additions (e.g. telemetry consent) are preserved from the first.
      ${pkgs.yq-go}/bin/yq eval-all \
        '. as $item ireduce ({}; . * $item)' \
        "$target" ${gooseConfigBase} > "$merged"
    else
      cp ${gooseConfigBase} "$merged"
    fi

    mv "$merged" "$target"
    chmod u+w "$target"
  '';

  # Goose Desktop keeps its own shortcuts in Electron userData, not XDG, and
  # ships defaults of cmd+alt+G (focus) and cmd+alt+shift+G (quick launcher).
  # quickLauncher is the counterpart to Claude Desktop's cmd+enter quick entry,
  # so it gets cmd+alt+enter: the same Enter key, one modifier along, and clear
  # of aerospace's bare alt+enter. The chord is registered in
  # modules/darwin/keybindings.nix so the conflict assertion knows it is taken.
  #
  # Key names read from the 1.44.0 app bundle, not a documented API, so an
  # upgrade could rename them. Goose fills the rest of keyboardShortcuts from
  # its own defaults, so writing this one key is enough.
  gooseDesktopSettingsBase = pkgs.writeText "goose-desktop-settings-base.json" (
    builtins.toJSON {
      keyboardShortcuts.quickLauncher = "CommandOrControl+Alt+Enter";
    }
  );

  # Goose Desktop rewrites settings.json whenever a setting changes, so this
  # merges at activation like config.yaml above rather than symlinking.
  updateGooseDesktopSettings = pkgs.writeShellScript "update-goose-desktop-settings" ''
    set -euo pipefail

    target="$HOME/Library/Application Support/Goose/settings.json"
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    merged="$(mktemp "''${target}.tmp.XXXXXX")"
    trap 'rm -f "$merged"' EXIT

    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" ${gooseDesktopSettingsBase} > "$merged"
    else
      cp ${gooseDesktopSettingsBase} "$merged"
    fi

    mv "$merged" "$target"
    chmod u+w "$target"
  '';

in
{
  # Goose reads `.goosehints` (the name is in the installed binary and is
  # already in CONTEXT_FILE_NAMES below). Nothing wrote a global one, so goose
  # ran without the shared conventions or the prohibitions.
  xdg.configFile."goose/.goosehints" = {
    text = kit.mkInstructionsWithStyle {
      harness = "goose";
      skillsRoot = "~/.claude/skills";
    };
    force = true;
  };

  home.sessionVariables = {
    CONTEXT_FILE_NAMES = builtins.toJSON [
      "AGENTS.md"
      ".goosehints"
      ".cursorrules"
      "CLAUDE.md"
      "CONSTITUTION.md"
      "CONTRIBUTING.md"
      "COPILOT.md"
    ];
    GOOSE_RECIPE_PATH = "${config.home.homeDirectory}/.config/goose/recipes";
    # Local Ollama endpoint. Switch provider at runtime with:
    #   GOOSE_PROVIDER=ollama GOOSE_MODEL=qwen2.5-coder:14b goose
    OLLAMA_HOST = "http://localhost:11434";
  };

  home.activation.gooseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateGooseConfig}
  '';

  home.activation.gooseDesktopSettings = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${updateGooseDesktopSettings}
    ''
  );

  home.packages = [ pkgs.goose-cli ];
}
