{
  lib,
  pkgs,
  values,
  ...
}:
let
  skillsLib = import ../shared/skills.nix { inherit lib pkgs; };
  mcpServers = import ../shared/mcp.nix { inherit lib values; };

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

  skillLinks = builtins.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (name: path: [
        {
          name = "claude/skills/${name}/SKILL.md";
          value.source = path;
        }
      ]) skillsLib.allSkills
    )
  );

in
{
  xdg.configFile = lib.mkMerge [
    {
      "Claude/claude_desktop_config.json".text = claudeConfig;
    }
    skillLinks
  ];

  xdg.dataFile = {
    "Claude/hooks/append_agentsmd_context.sh" = {
      text = claudeHookScript;
      executable = true;
    };
  };
}
