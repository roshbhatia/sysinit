{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  defaultInstructions = kit.mkInstructions "~/.claude/skills";

  claudeHookScript = ''
    #!/usr/bin/env bash
    set -euo pipefail
    content=""
    while IFS= read -r file; do
      content+="=== ''${file} ===
    $(cat "$file")

    "
    done < <(find "''${CLAUDE_PROJECT_DIR:-.}" -name "AGENTS.md" -type f 2>/dev/null | sort)
    [[ -n "$content" ]] && printf '%s' "$content" | jq -Rs '{"additionalContext": .}'
  '';

  subagents = lib.filterAttrs (
    n: _: n != "formatSubagentAsMarkdown"
  ) kit.llmLib.instructions.subagents;

  ccCfg = config.sysinit.llm.claudeCode;
  # Resolve relative paths against $HOME so the upstream module always
  # receives an absolute string (its `path` type rejects relatives).
  resolvePath = p: if lib.hasPrefix "/" p then p else "${config.home.homeDirectory}/${p}";
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    marketplaces = lib.mapAttrs (_: resolvePath) ccCfg.marketplaces;
    plugins = map resolvePath ccCfg.plugins;

    settings = {
      permissions = {
        allow = llmLib.allowlist.formatForClaude llmLib.allowlist.tierA;
      };

      editorMode = "vim";
      tui = "fullscreen";
      autoCompactWindow = 145000;
      autoMemoryEnabled = true;
      autoDreamEnabled = true;

      hooks = {
        SessionStart = [
          {
            matcher = "startup";
            hooks = [
              {
                type = "command";
                command = "${config.home.homeDirectory}/.claude/hooks/append_agentsmd_context";
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
                command = "claude-notifications handle-hook Stop";
                async = true;
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
                command = "claude-notifications handle-hook SubagentStop";
                async = true;
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
                command = "claude-notifications handle-hook PreToolUse";
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
      }
    ) subagents;
  };

  home = {
    packages = [ pkgs.claude-notifications-go ];

    file.".claude/hooks/append_agentsmd_context" = {
      text = claudeHookScript;
      executable = true;
    };

    file.".claude/claude-notifications-go/config.json".text = builtins.toJSON {
      notifyOnSubagentStop = true;
      notifyOnTextResponse = true;
      respectJudgeMode = false;
      suppressFilters = [ ];
    };
  };
}
