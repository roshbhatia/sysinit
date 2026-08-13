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

  defaultInstructions = kit.mkInstructions {
    harness = "claude";
    skillsRoot = "~/.claude/skills";
  };

  statuslineScript = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [
      pkgs.git
      pkgs.sysinit-agent
    ];
    bashOptions = [ ];
    text = ''
      exec sysinit-agent statusline "$@"
    '';
  };

  worklogScript = pkgs.writeShellApplication {
    name = "claude-worklog";
    runtimeInputs = [
      pkgs.uv
      pkgs.python3
      pkgs.git
    ];
    text = ''
      export UV_PYTHON=${pkgs.python3}/bin/python3
      export UV_PYTHON_DOWNLOADS=never
      exec uv run --script ${./worklog-hook.py}
    '';
  };

  bashGuardScript = llmLib.guards.mkBashGuard {
    inherit pkgs;
    name = "claude-bash-guard";
  };

  nixGuardScript = pkgs.writeShellApplication {
    name = "claude-nix-guard";
    runtimeInputs = [ pkgs.jq ];
    bashOptions = [ ];
    text = builtins.readFile ./nix-guard.sh;
  };

  slackGuardScript =
    let
      mkChanPat = channels: lib.concatStringsSep "|" (map (c: "\"${c}\"") channels);
      sendNowTools = lib.filter (
        t: !(lib.hasSuffix "schedule_message" t)
      ) llmLib.allowlist.slackSendTools;
      scheduleTools = lib.filter (lib.hasSuffix "schedule_message") llmLib.allowlist.slackSendTools;
      allowedChanBlock =
        if slackAllowedChannels != [ ] then
          ''
            case "$_channel" in
              ${mkChanPat slackAllowedChannels})
                exit 0
                ;;
            esac
          ''
        else
          "";
    in
    pkgs.writeShellApplication {
      name = "claude-slack-guard";
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = ''
        input="$(cat)"
        tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
        case "$tool" in
          ${lib.concatStringsSep " | " (map (t: "\"${t}\"") sendNowTools)})
            _channel="$(printf '%s' "$input" | jq -r '.tool_input.channel_id // empty' 2>/dev/null)"
            ${allowedChanBlock}jq -n '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: "Slack sends are gated to skill-approved channels. This destination is not in the allow-list."
              }
            }'
            ;;
          ${lib.concatStringsSep " | " (map (t: "\"${t}\"") scheduleTools)})
            jq -n '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: "Scheduled Slack sends are always blocked."
              }
            }'
            ;;
        esac
        exit 0
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
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        DISABLE_AUTOUPDATER = "1";
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
      fallbackModel = [ "claude-sonnet-5" ];
      alwaysThinkingEnabled = true;
      autoMemoryEnabled = true;
      outputStyle = "sysinit-ste";

      editorMode = "vim";

      includeCoAuthoredBy = false;

      statusLine = {
        type = "command";
        command = lib.getExe statuslineScript;
      };

      tui = "fullscreen";

      autoCompactEnabled = true;

      autoCompactWindow = 300000;

      disabledMcpServers = disabledBuiltinServers;

      # The marketplace name must equal the `name` in the repository's
      # `.claude-plugin/marketplace.json`, which Claude Code enforces.
      extraKnownMarketplaces = {
        openai-codex = {
          source = {
            source = "github";
            repo = "openai/codex-plugin-cc";
          };
        };
      };

      enabledPlugins = {
        "codex@openai-codex" = true;
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
              # On every prompt rather than at SessionEnd, because the point is
              {
                type = "command";
                command = "${profileBin}/sysinit-agent transcript-link claude";
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
                command = "${lib.getExe nixGuardScript}";
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
        # The same matcher the pre-edit guard uses, because the two hooks are interested
        # in exactly the same tool calls.
        PostToolUse = [
          {
            matcher = "Edit|Write|NotebookEdit";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-edit-event claude";
                async = true;
              }
              # Files a review note from the words the model already wrote about the
              # edit, so the notes exist whether or not it was asked for one.
              {
                type = "command";
                command = "${profileBin}/agent-note-auto claude";
                async = true;
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
                command = "${lib.getExe worklogScript}";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-state claude exit";
                async = true;
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
