{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  claudeEnabled = values.llm.claude.enabled or true;

  claudeConfig = builtins.toJSON {
    mcpServers = common.formatMcpForClaude mcpServers.servers;
  };
in
lib.mkIf claudeEnabled {
  home.activation.claudeDesktopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/Claude"

    cat > "$HOME/.config/Claude/claude_desktop_config.json" << 'EOF'
    ${claudeConfig}
    EOF
  '';
}
