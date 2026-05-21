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
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
  '';

  subagents = lib.filterAttrs (
    n: _: n != "formatSubagentAsMarkdown"
  ) kit.llmLib.instructions.subagents;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      permissions = {
        allow = llmLib.allowlist.formatForClaude llmLib.allowlist.tierA;
      };

      editorMode = "vim";
      tui = "fullscreen";

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

  home.file.".claude/hooks/append_agentsmd_context" = {
    text = claudeHookScript;
    executable = true;
  };
}
