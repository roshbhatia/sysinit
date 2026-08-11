{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  bundledExtensions = {
    computercontroller = {
      enabled = true;
      description = "macOS UI automation, web scraping, and office-document tools";
    };
    autovisualiser = {
      enabled = true;
      description = "Render charts and diagrams from data in the transcript";
    };
    memory = {
      enabled = false;
      description = "Goose-local categorized memory store";
    };
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

  # Servers this host stopped declaring, which goose's own rewrite kept on disk.
  # Both are reachable through `agentgateway`, which the catalog does declare, so
  # the direct entry is a duplicate rather than a loss. Named here because
  # `retire` otherwise reaches only `suppressedServers`, and an undeclared name
  # is not a suppressed one: they sat in `~/.config/goose/config.yaml` from
  # 2026-07-01 to 2026-08-11 with nothing reporting them.
  retiredExtensions = [
    "cocoindex"
    "incident-io"
  ];

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
    GOOSE_MODE = "auto";
    GOOSE_PROVIDER = "claude-acp";
    GOOSE_MODEL = "opus";
    GOOSE_TOOLSHIM = false;
    GOOSE_TELEMETRY_ENABLED = false;

    extensions =
      llmLib.mcp.formatForGoose kit.mcpServers.servers
      // lib.mapAttrs mkBundledExtension bundledExtensions
      // lib.mapAttrs mkPlatformExtension platformExtensions;
  };

  gooseDesktopSettings = {
    keyboardShortcuts.quickLauncher = "CommandOrControl+Alt+Enter";
  };
in
{
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
    OLLAMA_HOST = "http://localhost:11434";
  };

  sysinit.llm.managedFiles = {
    goose = {
      path = ".config/goose/config.yaml";
      format = "yaml";
      content = gooseSettings;
      enforce = [
        "GOOSE_MODE"
        "GOOSE_CLI_THEME"
      ]
      ++ map (name: [
        "extensions"
        name
      ]) (builtins.attrNames bundledExtensions);
      # goose rewrites config.yaml at runtime, so dropping a server from the
      # catalog is not enough: the on-disk entry is absent from the recorded
      # base and the merge keeps it. Delete what this host suppresses.
      #
      # Named one at a time rather than by enforcing the whole `extensions` map,
      # which is what `hermes.nix` does to `mcp_servers`. The two look alike and
      # are not: hermes keys hold MCP servers only, so the catalog is the complete
      # set. goose's `extensions` is a mixed namespace holding MCP servers, the
      # bundled extensions, and goose's own `platform` entries. On 2026-08-11 it
      # carried 12 keys this repository does not declare, of which 8 were live
      # work MCP servers and 2 were goose platform extensions (`skills` and
      # `orchestrator`). Enforcing the map would have deleted all of them.
      retire =
        map (name: [
          "extensions"
          name
        ]) config.sysinit.llm.mcp.suppressedServers
        ++ map (name: [
          "extensions"
          name
        ]) retiredExtensions;
    };
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    goose-desktop = {
      path = "Library/Application Support/Goose/settings.json";
      format = "json";
      content = gooseDesktopSettings;
    };
  };

}
