{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Goose's own bundled MCP servers, each reachable as `goose mcp <name>`.
  # Declared as `type = "stdio"` rather than `type = "builtin"` on purpose:
  # both shapes load the same server, but a builtin runs in-process and is
  # therefore invisible to an ACP provider, while a stdio extension is
  # forwarded to the agent as `mcp__<name>__<tool>`. With GOOSE_PROVIDER set
  # to claude-acp below, builtin would mean zero goose tools reach the model.
  bundledExtensions = {
    computercontroller = {
      enabled = true;
      description = "macOS UI automation, web scraping, and office-document tools";
    };
    autovisualiser = {
      enabled = true;
      description = "Render charts and diagrams from data in the transcript";
    };
    # Superseded by the basic-memory MCP server, which the whole fleet shares.
    # Goose's own store is per-harness and writes to ~/.config/goose/memory.
    memory = {
      enabled = false;
      description = "Goose-local categorized memory store";
    };
    # Injects "the user may be new to goose" guidance into every system prompt.
    tutorial = {
      enabled = false;
      description = "Built-in goose tutorials";
    };
  };

  mkBundledExtension = name: ext: {
    inherit (ext) description enabled;
    inherit name;
    args = [
      "mcp"
      name
    ];
    bundled = null;
    cmd = "${pkgs.goose-cli}/bin/goose";
    env_keys = [ ];
    envs = { };
    timeout = 300;
    type = "stdio";
  };

  # Goose's in-process extensions. `name` mirrors the value goose seeds itself,
  # because the activation merge is a deep merge: everything omitted here
  # (description, display_name, available_tools) is kept from goose's own copy.
  #
  # extensionmanager is off because it enables and disables extensions by
  # rewriting config.yaml, which this module owns. code_execution is off
  # because it is still experimental upstream.
  platformExtensions = {
    analyze = true;
    apps = true;
    chatrecall = true;
    code_execution = false;
    developer = true;
    extensionmanager = false;
    summarize = true;
    summon = true;
    todo = true;
    tom = true;
  };

  platformName = name: if name == "extensionmanager" then "Extension Manager" else name;

  mkPlatformExtension = name: enabled: {
    inherit enabled;
    bundled = true;
    name = platformName name;
    type = "platform";
  };

  gooseConfig = builtins.toJSON {
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    # Risk-assessed approval instead of blanket auto: goose prompts on
    # higher-risk actions, auto-runs the rest.
    GOOSE_MODE = "smart_approve";
    # Claude Code over ACP, through the claude-agent-acp adapter this repo
    # already installs (see lib/acp.nix). Without a provider and model here,
    # goose runs its first-run configuration wizard on every start.
    GOOSE_PROVIDER = "claude-acp";
    # Required by goose, but inert for this provider: the adapter never passes
    # a model flag to `claude`, so the model comes from ~/.claude/settings.json.
    # Change the model there, not here.
    GOOSE_MODEL = "opus";
    # Toolshim routes tool calls through a local ollama interpreter, for
    # providers with no native tool calling. claude-acp has native tools, so
    # leaving this on only adds a hop and a failure mode.
    GOOSE_TOOLSHIM = false;
    GOOSE_TELEMETRY_ENABLED = false;

    extensions =
      llmLib.mcp.formatForGoose kit.mcpServers.servers
      // lib.mapAttrs mkBundledExtension bundledExtensions
      // lib.mapAttrs mkPlatformExtension platformExtensions;
  };

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

    # `... style=""` is not cosmetic. yq carries each node's flow style over
    # from its input, and the base is JSON, so without the reset the merge
    # writes config.yaml as one unreadable single-line blob — which then seeds
    # the next merge and never recovers. `-o=yaml` alone does not undo it.
    if [ -f "$target" ]; then
      # yq (mikefarah/yq) handles both JSON and YAML input. eval-all reads
      # every doc and ireduce merges them; the later doc (our nix base)
      # wins on conflict for canonical fields, while goose's runtime
      # additions (e.g. telemetry consent) are preserved from the first.
      ${pkgs.yq-go}/bin/yq eval-all -o=yaml \
        '(. as $item ireduce ({}; . * $item)) | ... style=""' \
        "$target" ${gooseConfigBase} > "$merged"
    else
      ${pkgs.yq-go}/bin/yq eval -o=yaml '... style=""' ${gooseConfigBase} > "$merged"
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
    # Local Ollama endpoint. Switch provider per run without touching config:
    #   goose run --provider ollama --model qwen2.5-coder:14b -t '...'
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
