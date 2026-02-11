{
  lib,
  values,
  ...
}:
let
  skills = import ../skills.nix {
    inherit lib;
    pkgs = null;
  };
  instructionsLib = import ../instructions.nix;
  mcpServers = import ../mcp.nix { inherit lib values; };

  formatMcpForClaude = builtins.mapAttrs (
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
  );

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

  subagentFiles = lib.mapAttrs' (
    name: config:
    lib.nameValuePair ".claude/agent/${name}.md" {
      text = instructionsLib.formatSubagentAsMarkdown { inherit name config; };
      force = true;
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") instructionsLib.subagents);

in
{
  xdg.configFile = lib.mkMerge [
    {
      "claude/claude_desktop_config.json" = {
        text = claudeConfig;
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
