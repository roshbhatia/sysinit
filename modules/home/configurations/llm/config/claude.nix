{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../mcp.nix { inherit lib values; };
  mcpFormatters = import ../mcp-formatters.nix { inherit lib; };

  claudeConfig = builtins.toJSON {
    mcpServers = mcpFormatters.formatMcpFor "claude" mcpServers.servers;
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
    "claude/claude_desktop_config.json" = {
      text = claudeConfig;
      force = true;
    };
  };

  xdg.dataFile = {
    "claude/hooks/append_agentsmd_context.sh" = {
      text = claudeHookScript;
      executable = true;
      force = true;
    };
  };
}
