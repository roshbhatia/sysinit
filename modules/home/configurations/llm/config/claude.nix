{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;

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
in
{
  home.activation.claudeDesktopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/Claude"

    cat > "$HOME/.config/Claude/claude_desktop_config.json" << 'EOF'
    ${claudeConfig}
    EOF
  '';

  home.activation.claudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create Claude hooks directory and script
        $DRY_RUN_CMD mkdir -p "$HOME/.claude/hooks"

        cat > "$HOME/.claude/hooks/append_agentsmd_context.sh" << 'EOF'
    #!/bin/bash
    # Find all AGENTS.md files in current directory and subdirectories
    # This is a temporary solution for case that Claude Code not satisfies with AGENTS.md usage case.
    echo "=== AGENTS.md Files Found ==="
    find "$CLAUDE_PROJECT_DIR" -name "AGENTS.md" -type f | while read -r file; do
        echo "--- File: $file ---"
        cat "$file"
        echo ""
    done
    EOF

        # Make the hook script executable
        $DRY_RUN_CMD chmod +x "$HOME/.claude/hooks/append_agentsmd_context.sh"
  '';
}
