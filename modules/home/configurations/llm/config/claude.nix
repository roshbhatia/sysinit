{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };

  # Claude-specific MCP formatter
  formatMcpForClaude =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
          description = server.description or "";
          enabled = server.enabled or true;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
          description = server.description or "";
          enabled = server.enabled or true;
          env = server.env or { };
        }
    ) mcpServers;

  claudeConfig = builtins.toJSON {
    mcpServers = formatMcpForClaude mcpServers.servers;
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
  claudeConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "Claude/claude_desktop_config.json";
    text = claudeConfig;
    force = false; # Preserve user edits when source unchanged
  };

  claudeHookScriptFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "claude/hooks/append_agentsmd_context.sh";
    text = claudeHookScript;
    executable = true;
    force = false; # Preserve user edits when source unchanged
  };
in
{
  home.activation = {
    claudeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] claudeConfigFile.script;
    claudeHook = lib.hm.dag.entryAfter [ "linkGeneration" ] claudeHookScriptFile.script;
  };
}
