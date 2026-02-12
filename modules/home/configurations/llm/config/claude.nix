{
  lib,
  pkgs,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    skillsRoot = "~/.claude/skills";
  };

  claudeConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForClaude mcpServers.servers;
    hooks = {
      SessionStart = [
        {
          matcher = "startup";
          hooks = [
            {
              type = "command";
              command = "$CLAUDE_PROJECT_DIR/.claude/hooks/append_agentsmd_context.sh";
            }
          ];
        }
      ];
    };
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

  subagentFiles = lib.mapAttrs' (
    name: config:
    lib.nameValuePair ".claude/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown { inherit name config; };
      force = true;
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents);

in
{
  xdg.configFile = lib.mkMerge [
    {
      "claude/claude_desktop_config.json" = {
        text = claudeConfig;
        force = true;
      };
    }
    {
      "claude/CLAUDE.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];

  xdg.dataFile = {
    "claude/hooks/append_agentsmd_context.sh" = {
      text = claudeHookScript;
      executable = true;
      force = true;
    };
  };
}
