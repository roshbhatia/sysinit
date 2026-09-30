{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";
  commandPath = llmLib.commandPath.renderFor pkgs.stdenv.hostPlatform.isDarwin profileBin;

  gateHookScript = llmLib.guards.mkGateHookScript {
    inherit pkgs;
    name = "codex-gate-hook";
    harness = "codex";
    event = "PreToolUse";
  };
  gateHook =
    event:
    llmLib.guards.mkGateHook {
      inherit pkgs event;
      harness = "codex";
    };

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
in
{
  home = {
    packages = [ gateHookScript ];
    activation.codexNativeTools = lib.hm.dag.entryBetween [ "llmManagedFiles" ] [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe nativeToolsPython} ${./codex-native-tools.py}
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
          ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
        };
      };

      tools = {
        web_search = true;
      };

      features = {
        hooks = true;
        multi_agent = true;
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

      hooks = {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/orc session register --hook-input --bind-current --source hook --harness codex --quiet";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe gateHookScript}";
              }
            ];
          }
        ];
        PostToolUse = [
          {

            hooks = [
              {
                type = "command";
                command = gateHook "PostToolUse";
              }
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state codex working submit";
              }
              {
                type = "command";
                command = gateHook "UserPromptSubmit";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-notify codex done ${profileBin}/agent-focus";
              }
              {
                type = "command";
                command = "${profileBin}/agent-state codex done \"your move\"";
              }
            ];
          }
        ];
      };
    };
  };
}
