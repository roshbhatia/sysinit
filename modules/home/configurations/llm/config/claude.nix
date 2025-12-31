{
  lib,
  values,
  ...
}:
let
  llmLib = import ../../../shared/lib/llm { inherit lib; };
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };

  claudeConfig = builtins.toJSON {
    mcpServers = llmLib.formatMcpForClaude mcpServers.servers;
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
in
{
  xdg.configFile = {
    "Claude/claude_desktop_config.json".text = claudeConfig;
  };

  xdg.dataFile = {
    "Claude/hooks/append_agentsmd_context.sh" = {
      text = claudeHookScript;
      executable = true;
    };
  };
}
