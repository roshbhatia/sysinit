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
  commandPath = llmLib.commandPath.render profileBin;

  defaultInstructions = kit.mkInstructions {
    harness = "claude";
    skillsRoot = "~/.claude/skills";
  };

  bashGuardScript = llmLib.guards.mkBashGuard {
    inherit pkgs;
    name = "claude-bash-guard";
  };

  slackGuardScript =
    let
      sendNowTools = lib.filter (
        t: !(lib.hasSuffix "schedule_message" t)
      ) llmLib.allowlist.slackSendTools;
      scheduleTools = lib.filter (lib.hasSuffix "schedule_message") llmLib.allowlist.slackSendTools;
    in
    pkgs.writeShellApplication {
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
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      env = {
        PATH = commandPath;
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        DISABLE_AUTOUPDATER = "1";

        # Traces need the beta flag on top of the telemetry switch; the switch
        # alone emits logs and metrics only. A run with no collector listening
        # on 4318 costs nothing measurable and prints no error, so these stay on.
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";
        OTEL_TRACES_EXPORTER = "otlp";
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";

        # Without this, every prompt attribute reads <REDACTED> and a turn row
        # carries no text. The collector writes to a local file only.
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
          ++ llmLib.allowlist.tierMcp;
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

      # No autoCompactWindow. The CLI reads it as a hard token ceiling, not a
      # headroom margin, and its schema floor is 1e5. That floor is a tenth of
      # Opus 5's 1M window, so auto-compact fired about ten times per session.
      # Unset is the CLI's "auto" state: it resolves the window from the model.
      # The same value also binds every in-process subagent, so a literal 1e6
      # here would overshoot on any Sonnet or Haiku teammate.

      disabledMcpServers = disabledBuiltinServers;

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

      # A language server answers "where is this defined" and "what calls this"
      # from a real index, in one call. The alternative is a grep sweep that reads
      # whole files to reach the same answer, so this trades a variable read bill
      # for a fixed one.
      #
      # These four plugins carry no skill, agent or command: each is an
      # `lspServers` entry and nothing else, so the always-on prompt cost is zero
      # and the server only starts when a file with a matching extension is
      # touched. Every binary below already comes from modules/home/packages.nix.
      # rust-analyzer and clangd are on this machine too, but no Rust or C work
      # runs here, so they stay off until it does.
      enabledPlugins = {
        "codex@openai-codex" = true;
        "gopls-lsp@claude-plugins-official" = true; # gopls
        "typescript-lsp@claude-plugins-official" = true; # typescript-language-server
        "pyright-lsp@claude-plugins-official" = true; # pyright-langserver
        "lua-lsp@claude-plugins-official" = true; # lua-language-server
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
                command = "${profileBin}/agent-edit-event claude --prompt";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-note-open";
              }
              {
                type = "command";
                command = "${profileBin}/prose-gate remind";
              }
              {
                type = "command";
                command = "${profileBin}/utils transcript-link claude";
                async = true;
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe bashGuardScript}";
              }
            ];
          }
          {
            matcher = "Edit|Write|NotebookEdit";
            hooks = [
              {
                type = "command";
                command = "${pkgs.sysinit-utils}/bin/nix-guard";
              }
            ];
          }
          {
            matcher = "Read";
            hooks = [
              {
                type = "command";
                command = "${pkgs.sysinit-utils}/bin/read-guard";
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
            matcher = "Edit|Write|NotebookEdit";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-edit-event claude";
                async = true;
              }
            ];
          }
          {
            matcher = "Edit|Write|MultiEdit";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/lint-gate";
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
                command = "${profileBin}/orc session register --hook-input --source hook --harness claude --quiet";
              }
            ];
          }
          {
            # Not the empty matcher. `resume` and `fork` replay a transcript that
            # already carries this injection, so matching them states the same
            # four rules twice. `startup`, `clear` and `compact` are the three
            # starts that genuinely have no copy of them.
            matcher = "startup|clear|compact";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/prose-gate session";
              }
            ];
          }
        ];
        SubagentStop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/prose-gate subagent";
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
                command = "${profileBin}/worklog";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-state claude exit";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/orc session archive --hook-input --quiet";
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
                command = "${profileBin}/loop-gate check";
              }
              {
                type = "command";
                command = "${profileBin}/prose-gate check";
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
