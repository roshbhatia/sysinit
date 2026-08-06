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

  gooseSettings = {
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    # Run every tool call without an approval prompt, matching claude's
    # dangerouslySkipPermissions, codex's approval_policy = "never", and
    # opencode's blanket permission allow. The destructive-command guards are
    # the gate across the fleet, not per-harness prompting: a prompt the owner
    # answers by reflex is not a control, and only goose was still asking.
    GOOSE_MODE = "auto";
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
  gooseDesktopSettings = {
    keyboardShortcuts.quickLauncher = "CommandOrControl+Alt+Enter";
  };
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

  # Goose rewrites config.yaml at runtime (the first-run telemetry answer, for
  # one), so it cannot be a store symlink. The shared reconciler owns it.
  sysinit.llm.managedFiles = {
    goose = {
      path = ".config/goose/config.yaml";
      format = "yaml";
      content = gooseSettings;
      # GOOSE_MODE gates which actions run without approval, so a value goose
      # drops or rewrites must come back rather than stand.
      #
      # `extensions` as a whole is deliberately NOT enforced. Goose fills in
      # description, display_name, and available_tools at runtime, and the
      # deep merge keeps them, which is the behaviour the comment on
      # `platformExtensions` above describes. Enforcing the block would strip
      # those fields on every activation and goose would write them back.
      # GOOSE_CLI_THEME is enforced too: it must always be ansi, so the
      # terminal's own palette drives it and goose stays consistent with every
      # other harness under stylix. Goose rewrites it when the theme is changed
      # from inside the TUI, and without enforcement that choice would stand.
      #
      # autovisualiser is the one extension that has to be enforced, and it is
      # written as a path so the other seventeen still merge normally. Goose keeps
      # rewriting it back to `type: builtin`, which drops `cmd`, and that is a
      # conflict the merge cannot resolve: the live file deleted a key the Nix
      # content changed, so activation aborts and every other key stops updating
      # with it. Builtin is also the wrong answer here for the reason given above
      # `bundledExtensions`: it runs in-process and is invisible to the ACP
      # provider, so under GOOSE_PROVIDER=claude-acp its tools reach no model.
      enforce = [
        "GOOSE_MODE"
        "GOOSE_CLI_THEME"
        [
          "extensions"
          "autovisualiser"
        ]
      ];
    };
  }
  # Goose Desktop keeps settings in Electron userData and rewrites the file
  # whenever a setting changes. It exists on Darwin only.
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    goose-desktop = {
      path = "Library/Application Support/Goose/settings.json";
      format = "json";
      content = gooseDesktopSettings;
    };
  };

  home.packages = [ pkgs.goose-cli ];
}
