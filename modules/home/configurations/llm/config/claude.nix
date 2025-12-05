{
  lib,
  pkgs,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  writableConfigs = import ../shared/writable-configs.nix { inherit lib pkgs; };

  claudeConfig = builtins.toJSON {
    mcpServers = common.formatMcpForClaude mcpServers.servers;
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
    # Find all AGENTS.md files in current directory and subdirectories
    # This is a temporary solution for case that Claude Code not satisfies with AGENTS.md usage case.
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
  '';

  # Create writable config files
  claudeConfigFile = writableConfigs.mkWritableConfig {
    path = "Claude/claude_desktop_config.json";
    text = claudeConfig;
    force = false; # Preserve user edits when source unchanged
  };

  claudeHookScriptFile = writableConfigs.mkWritableConfig {
    path = "claude/hooks/append_agentsmd_context.sh";
    text = claudeHookScript;
    executable = true;
    force = false; # Preserve user edits when source unchanged
  };
in
{
  home.activation = {
    claudeConfig = claudeConfigFile.activation;
    claudeHook = claudeHookScriptFile.activation;
  };
}
