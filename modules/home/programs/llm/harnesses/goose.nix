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
      retire = map (name: [
        "extensions"
        name
      ]) config.sysinit.llm.mcp.suppressedServers;
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
