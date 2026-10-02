{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };
  routeServer = import ../lib/mcp-routing.nix { inherit lib pkgs; };

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

  mkBundledExtension =
    name: ext:
    mkLocalExtension name {
      inherit (ext) description enabled;
      args = [
        "mcp"
        name
      ];
      cmd = "${pkgs.goose-cli}/bin/goose";
    };

  localExtensions = {
    codex-mcp = {
      enabled = true;
      description = "Codex CLI as MCP server, to delegate a coding task to Codex";
      cmd = "${lib.getExe pkgs.codex}";
      args = [ "mcp-server" ];
    };
  };

  gooseName = name: (lib.toUpper (builtins.substring 0 1 name)) + builtins.substring 1 (-1) name;

  mkLocalExtension =
    name: ext:
    let
      routed = routeServer name {
        command = ext.cmd;
        inherit (ext) args description enabled;
      };
    in
    {
      inherit (routed) args description enabled;
      cmd = routed.command;
      bundled = null;
      env_keys = [ ];
      envs = { };
      name = gooseName name;
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
    orchestrator = false;
    scheduler = true;
    skills = true;
    summarize = true;
    summon = true;
    todo = true;
    tom = true;
  };

  gooseMcpServers = kit.mcpServers.serversFor "goose";

  retiredExtensions = [
    "cocoindex"
    "figma"
    "incident-io"
    "launchdarkly-ai-configs"
    "laurel-ask"
    "lucidchart"
    "supabase"
    "wiz"
    "work-graph"
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

    providers = {
      claude-acp = {
        configured = true;
        enabled = true;
        model = "opus";
      };
      codex-acp = {
        configured = true;
        enabled = true;
        model = "gpt-5.2-codex";
      };
    };
    GOOSE_TOOLSHIM = false;

    GOOSE_TELEMETRY_ENABLED = true;

    extensions =
      llmLib.mcp.formatForGoose gooseMcpServers
      // lib.mapAttrs mkBundledExtension bundledExtensions
      // lib.mapAttrs mkLocalExtension localExtensions
      // lib.mapAttrs mkPlatformExtension platformExtensions;
  };

  gooseDesktopSettings = {
    keyboardShortcuts.quickLauncher = "CommandOrControl+Alt+Enter";
  };

  goosePermissions = {
    user = {
      always_allow = [ "shell" ];
      ask_before = [ ];
      never_allow = [ ];
    };
    smart_approve = {
      always_allow = [ ];
      ask_before = [
        "edit"
        "shell"
        "todo__todo_write"
        "write"
      ];
      never_allow = [ ];
    };
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
        "GOOSE_PROVIDER"
        "GOOSE_MODEL"
      ]
      ++
        map
          (name: [
            "extensions"
            name
          ])

          (builtins.attrNames bundledExtensions ++ builtins.attrNames localExtensions)
      ++ map (name: [
        "extensions"
        name
        "enabled"
      ]) (builtins.attrNames gooseMcpServers ++ builtins.attrNames platformExtensions);
      retire =
        map
          (name: [
            "extensions"
            name
          ])
          (
            lib.unique (
              config.sysinit.llm.mcp.suppressedServers
              ++ (config.sysinit.llm.mcp.harnessSuppressedServers.goose or [ ])
            )
          )
        ++ map (name: [
          "extensions"
          name
        ]) retiredExtensions;
    };

    goose-permission = {
      path = ".config/goose/permission.yaml";
      format = "yaml";
      content = goosePermissions;
      enforce = [ "user" ];
    };
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    goose-desktop = {
      path = "Library/Application Support/Goose/settings.json";
      format = "json";
      content = gooseDesktopSettings;
    };
  };

}
