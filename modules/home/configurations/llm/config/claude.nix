{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };

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
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
  '';

  claudeConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "Claude/claude_desktop_config.json";
    text = claudeConfig;
  };

  claudeHookScriptFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "claude/hooks/append_agentsmd_context.sh";
    text = claudeHookScript;
    executable = true;
  };
in
{
  home.activation = {
    claudeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] claudeConfigFile.script;
    claudeHook = lib.hm.dag.entryAfter [ "linkGeneration" ] claudeHookScriptFile.script;
  };
}
