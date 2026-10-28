{
  lib,
  pkgs,
  config,
  osConfig ? { },
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";
  commandPath =
    llmLib.commandPath.renderHomeFor pkgs.stdenv.hostPlatform.isDarwin profileBin
      config.home.homeDirectory;

  nativeHooks = import ../lib/codex-hooks.nix {
    inherit lib pkgs profileBin;
  };
  systemHooks = osConfig.sysinit.codex.systemHooks.enable or false;

  otlpHttp = signal: {
    endpoint = "http://127.0.0.1:4318/v1/${signal}";
    protocol = "json";
  };

  compactPrompt = ''
    Compact this Codex session for continuation. Preserve only context needed to keep working correctly.

    Keep:
    - The newest user request and any later corrections or overrides.
    - Current cwd, repo, branch, git status summary, active OpenSpec change names, and task status.
    - Files changed, decisions made, validation commands and results, blockers, running sessions, ports, and PIDs.
    - Harness-specific findings: hook event names, config paths, MCP shape differences, and docs already verified.
    - Any user-owned dirty files that must not be reverted.

    Drop:
    - Verbose command output after the relevant result has been captured.
    - Superseded exploration, duplicate file reads, and stale plans.
    - Source excerpts that are no longer needed for the next action.

    End with the exact next action to take.
  '';

  codexProfiles = {
    default.model_reasoning_effort = "low";
    spec = {
      model_reasoning_effort = "high";
      model_reasoning_summary = "detailed";
    };
  };

  codexMcpServers = lib.mapAttrs (
    name: server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = [
        "description"
        "headers"
        "type"
      ];
      extraTransforms = [
        (s: s // lib.optionalAttrs (s.headers or { } != { }) { http_headers = s.headers; })
        lib.hm.mcp.addType
        (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
      ];
    }
  ) (kit.mcpServers.serversFor "codex");

  codexManagedFiles = [ "config.toml" ] ++ map (n: "${n}.config.toml") (lib.attrNames codexProfiles);
  nativeToolsPython = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  daemonCommand = [
    "${config.programs.codex.package}/bin/codex"
    "app-server"
    "--listen"
    "unix://"
    "--managed-daemon"
  ];
in
{
  launchd.agents.codex-app-server =
    lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.programs.codex.enable)
      {
        enable = true;
        config = {
          ProgramArguments = daemonCommand;
          WorkingDirectory = config.home.homeDirectory;
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 10;
          ExitTimeOut = 300;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/codex-app-server.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/codex-app-server.error.log";
        };
      };

  systemd.user.services.codex-app-server =
    lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.programs.codex.enable)
      {
        Unit.Description = "Shared local Codex app-server";
        Service = {
          ExecStart = lib.escapeShellArgs daemonCommand;
          WorkingDirectory = config.home.homeDirectory;
          Restart = "always";
          RestartSec = 10;
          TimeoutStopSec = 300;
        };
        Install.WantedBy = [ "default.target" ];
      };

  home = {
    inherit (nativeHooks) packages;
    activation.codexNativeTools = lib.hm.dag.entryBetween [ "llmManagedFiles" ] [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe nativeToolsPython} ${./codex-native-tools.py}
    '';
    activation.codexPluginHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.python3} ${./codex-plugin-hooks.py}
    '';
    file = lib.genAttrs (map (f: ".codex/${f}") codexManagedFiles) (_: {
      enable = lib.mkForce false;
    });
  };

  assertions = [
    {
      assertion = !config.home.preferXdgDirectories;
      message = "llm/codex: home.preferXdgDirectories moves programs.codex to .config/codex, but sysinit.llm.managedFiles still points at .codex. Update the paths in harnesses/codex.nix together with the flag.";
    }
  ];

  sysinit.llm.managedFiles = lib.listToAttrs (
    map (
      f:
      lib.nameValuePair "codex-${f}" {
        path = ".codex/${f}";
        format = "toml";
        contentFile = config.home.file.".codex/${f}".source;
        retire = lib.optionals (f == "config.toml") [
          [
            "tools"
            "web_search"
          ]
        ];
        enforce = lib.optionals (f == "config.toml") [
          "approval_policy"
          "sandbox_mode"
          [
            "plugins"
            "computer-use@openai-bundled"
            "enabled"
          ]
          [
            "desktop"
            "external-agent-import-sync-enabled"
          ]
        ];
      }
    ) codexManagedFiles
  );

  programs.codex = {
    enable = true;
    enableMcpIntegration = false;
    context = kit.mkInstructionsWithStyle {
      harness = "codex";
      skillsRoot = "~/.claude/skills";
    };
    plugins = [ ];

    profiles = codexProfiles;

    settings = {
      check_for_update_on_startup = false;
      suppress_unstable_features_warning = true;
      compact_prompt = compactPrompt;
      mcp_servers = codexMcpServers;
      plugins."computer-use@openai-bundled".enabled = false;

      approval_policy = "never";

      sandbox_mode = "danger-full-access";

      desktop."external-agent-import-sync-enabled" = false;

      tui = {
        fullscreen_transcript = true;
        alternate_screen = "always";
      };

      otel = {

        exporter."otlp-http" = otlpHttp "logs";
        trace_exporter."otlp-http" = otlpHttp "traces";
        metrics_exporter."otlp-http" = otlpHttp "metrics";

        log_user_prompt = true;
      };

      shell_environment_policy = {
        experimental_use_profile = true;
        set = {
          PATH = commandPath;
        };
      };

      web_search = "live";

      features = {
        hooks = true;
        multi_agent = true;
        # The service owns startup; clients still reuse its running server.
        daemon_auto_start = false;
      };

      agents = {
        max_threads = 6;
        max_depth = 1;
        explore = {
          description = "Read-only planning and exploration agent for understanding code, OpenSpec changes, options, and tradeoffs before implementation.";
          nickname_candidates = [
            "Explore"
            "Planner"
            "Plan"
          ];
        };
      };

      hooks = lib.mkIf (!systemHooks) nativeHooks.hooks;
    };
  };
}
