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

  # Declared here rather than in mcp-servers.nix, which every harness reads: a
  # tool that delegates coding to Codex earns its tokens from goose and is noise
  # inside Codex itself. Absolute path because goose desktop launches with no
  # PATH, and a bare `codex` did not resolve there.
  localExtensions = {
    codex-mcp = {
      enabled = true;
      description = "Codex CLI as MCP server, to delegate a coding task to Codex";
      cmd = "${lib.getExe pkgs.codex}";
      args = [ "mcp-server" ];
    };
  };

  # Goose capitalizes an extension's display name and rewrites the file if it
  # disagrees, so it is written the way goose would write it.
  gooseName = name: (lib.toUpper (builtins.substring 0 1 name)) + builtins.substring 1 (-1) name;

  mkLocalExtension = name: ext: {
    inherit (ext)
      args
      cmd
      description
      enabled
      ;
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

  # Dropped from the file rather than left disabled. `work-graph` pointed at a
  # store path the collector had already taken, and the rest were clicked in
  # through the Goose UI for a tool this host no longer reaches.
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

    # goose 1.28 carries two ACP bridges, `claude-acp` and `codex-acp`, and both
    # binaries are already on PATH from `home.packages`. Declared, not enforced:
    # `active_provider` is how the desktop switches between them, and that choice
    # is the app's to make. GOOSE_PROVIDER above is the CLI default.
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
    # The collector on 4318 is the sink; the Rust SDK reads OTEL_EXPORTER_OTLP_ENDPOINT
    # from the process environment, which modules/home/programs/otel-collector.nix sets.
    GOOSE_TELEMETRY_ENABLED = true;

    extensions =
      llmLib.mcp.formatForGoose kit.mcpServers.servers
      // lib.mapAttrs mkBundledExtension bundledExtensions
      // lib.mapAttrs mkLocalExtension localExtensions
      // lib.mapAttrs mkPlatformExtension platformExtensions;
  };

  gooseDesktopSettings = {
    keyboardShortcuts.quickLauncher = "CommandOrControl+Alt+Enter";
  };
  # goose's own approval file. It denies whole tools, never command globs, so it
  # cannot carry this repo's destructive deny list. Declared to make the policy
  # reproducible, not to tighten it.
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
      # Only the `enabled` leaf for a server, not the whole object: goose adds
      # `display_name` and `available_tools` of its own, and enforcing the object
      # would delete them on every switch.
      # Enforcing the leaf repairs it at switch time; it does not lock it, so
      # whatever rewrote every extension to `enabled: false` can do so again.
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
          # The whole object for these, not the `enabled` leaf. `codex-mcp` was
          # added to the live file by hand with `cmd: codex`, and a bare name does
          # not resolve under a GUI launch. Two independent additions of a
          # different value at one path is a conflict that refuses the whole file,
          # so Nix owns every key of an extension it defines outright.
          (builtins.attrNames bundledExtensions ++ builtins.attrNames localExtensions)
      ++ map (name: [
        "extensions"
        name
        "enabled"
      ]) (builtins.attrNames kit.mcpServers.servers ++ builtins.attrNames platformExtensions);
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
    # goose's real approval file, which was hand-made and unmanaged until now.
    # goose denies whole tools, never command globs, so this cannot carry the
    # repo's destructive deny list and `guard` stays "none". Declared to keep the
    # policy reproducible, not to tighten it: `shell` stays in always_allow.
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
