{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";
  commandPath =
    llmLib.commandPath.renderHomeFor pkgs.stdenv.hostPlatform.isDarwin profileBin
      config.home.homeDirectory;
  worklogHook = llmLib.worklog.mkHook { inherit pkgs config; };

  defaultInstructions = kit.mkInstructions {
    harness = "claude";
    skillsRoot = "~/.claude/skills";
  };

  gateHook =
    event:
    llmLib.guards.mkGateHook {
      inherit pkgs event;
      harness = "claude";
    };

  slackGuardScript =
    let
      sendNowTools = lib.filter (
        t: !(lib.hasSuffix "schedule_message" t)
      ) llmLib.allowlist.slackSendTools;
      scheduleTools = lib.filter (lib.hasSuffix "schedule_message") llmLib.allowlist.slackSendTools;
    in
    pkgs.sysinit.writeShellApplication {
      name = "claude-slack-guard";
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = ''
        send_now_tools=${lib.escapeShellArg (builtins.toJSON sendNowTools)}
        schedule_tools=${lib.escapeShellArg (builtins.toJSON scheduleTools)}
        allowed_channels=${lib.escapeShellArg (builtins.toJSON slackAllowedChannels)}

        ${builtins.readFile ./slack-guard.sh}
      '';
    };

  slackToolMatcher = lib.concatStringsSep "|" llmLib.allowlist.slackSendTools;

  steOutputStyle = ''
    ---
    name: sysinit-ste
    description: Simplified Technical English, ADHD-shaped output
    ---

    ${kit.llmLib.instructions.outputStyleRules}
  '';

  subagents = kit.llmLib.instructions.subagentDefs;

  disabledBuiltinServers = config.sysinit.llm.mcp.disabledBuiltinServers;
  slackAllowedChannels = config.sysinit.llm.mcp.slackAllowedSendChannels;

  claudeMcpServers = lib.mapAttrs (
    name: server:
    lib.hm.mcp.transformMcpServer {
      server = removeAttrs server [ "type" ];
      exclude = [ "enabled" ];
      extraTransforms = [
        lib.hm.mcp.addType
        (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
      ];
    }
  ) (kit.mcpServers.serversFor "claude");
in
{
  imports = [ ./mods.nix ];

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = false;
    mcpServers = claudeMcpServers;

    settings = {
      env = {
        PATH = commandPath;
        ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        DISABLE_AUTOUPDATER = "1";

        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";
        OTEL_TRACES_EXPORTER = "otlp";
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";

        OTEL_LOG_USER_PROMPTS = "1";
      };

      teammateMode = "in-process";

      dangerouslySkipPermissions = true;

      sandbox = {
        enabled = false;
      };

      permissions = {
        allow =
          llmLib.allowlist.formatForClaude llmLib.allowlist.tierA
          ++ llmLib.allowlist.formatForClaude llmLib.allowlist.tierB
          ++ llmLib.allowlist.tierMcp
          ++ (config.sysinit.llm.mcp.harnessAllowedTools.claude or [ ]);
      };

      fileCheckpointingEnabled = true;
      effortLevel = "high";
      alwaysThinkingEnabled = true;
      autoMemoryEnabled = true;
      outputStyle = "sysinit-ste";

      editorMode = "vim";

      statusLine = {
        type = "command";
        command = "${pkgs.sysinit-utils}/bin/agent-statusline";
      };

      tui = "fullscreen";

      autoCompactEnabled = true;

      disabledMcpServers = disabledBuiltinServers;

      disableClaudeAiConnectors = true;

      extraKnownMarketplaces = {
        openai-codex = {
          source = {
            source = "github";
            repo = "openai/codex-plugin-cc";
          };
        };
        claude-plugins-official = {
          source = {
            source = "github";
            repo = "anthropics/claude-plugins-official";
          };
        };
      };

      enabledPlugins = {
        "codex@openai-codex" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "lua-lsp@claude-plugins-official" = true;
      };

      hooks = {
        UserPromptSubmit = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state claude working submit";
                async = true;
              }
              {
                type = "command";
                command = gateHook "UserPromptSubmit";
              }
            ];
          }
        ];
        PreToolUse = [
          {

            matcher = "";
            hooks = [
              {
                type = "command";
                command = gateHook "PreToolUse";
              }
            ];
          }
          {
            matcher = slackToolMatcher;
            hooks = [
              {
                type = "command";
                command = "${lib.getExe slackGuardScript}";
              }
            ];
          }
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state claude working tool";
                async = true;
              }
            ];
          }
        ];
        PostToolUse = [
          {

            matcher = "";
            hooks = [
              {
                type = "command";
                command = gateHook "PostToolUse";
              }
            ];
          }
        ];
        SubagentStart = [
          {

            matcher = "";
            hooks = [
              {
                type = "command";
                command = gateHook "SubagentStart";
              }
            ];
          }
        ];
        SessionStart = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = llmLib.guards.withOrcSession "${profileBin}/orc session register --hook-input --bind-current --source hook --harness claude --quiet";
              }
            ];
          }
          {

            matcher = "startup|clear|compact";
            hooks = [
              {
                type = "command";
                command = gateHook "SessionStart";
              }
            ];
          }
        ];
        SessionEnd = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = worklogHook;
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-state claude exit";
                async = true;
              }
              {
                type = "command";
                command = llmLib.guards.withOrcSession "${profileBin}/orc session archive --hook-input --quiet";
              }
            ];
          }
        ];
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-prompt claude attention ${profileBin}/agent-focus";
                async = true;
              }
            ];
          }
        ];
        Stop = [
          {
            matcher = "";
            hooks = [
              {

                type = "command";
                command = gateHook "Stop";
              }
              {
                type = "command";
                command = "${profileBin}/agent-notify claude done ${profileBin}/agent-focus";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-state claude done \"your move\"";
                async = true;
              }
            ];
          }
        ];
      };
    };

    context = defaultInstructions;

    agents = lib.mapAttrs (
      name: agentConfig:
      kit.llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
        harness = "claude";
      }
    ) subagents;
  };

  home.file.".claude/output-styles/sysinit-ste.md" = {
    text = steOutputStyle;
    force = true;
  };

  sysinit.llm.managedFiles.claude-json = {
    enable = disabledBuiltinServers != [ ];
    path = ".claude.json";
    format = "json";
    content.disabledMcpServers = disabledBuiltinServers;
    enforce = [ "disabledMcpServers" ];
    createIfMissing = false;
  };
}
