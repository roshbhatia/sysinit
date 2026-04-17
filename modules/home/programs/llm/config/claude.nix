{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    skillsRoot = "~/.claude/skills";
  };

  claudeHookScript = ''
    #!/bin/bash
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
  '';

  subagents = lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
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

    memory.text = defaultInstructions;

    agents = lib.mapAttrs (
      name: agentConfig:
      llmLib.instructions.formatSubagentAsMarkdown { inherit name; config = agentConfig; }
    ) subagents;

  };

  home.file.".claude/hooks/append_agentsmd_context" = {
    text = claudeHookScript;
    executable = true;
  };
}
