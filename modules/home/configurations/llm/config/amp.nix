{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  ampEnabled = values.llm.amp.enabled or false;

  ampConfig = builtins.toJSON {
    mcpServers = mcpServers.servers;
    permissions = [
      {
        tool = "Bash";
        matches = {
          cmd = "*git commit*";
        };
        action = "ask";
      }
      {
        tool = "Bash";
        matches = {
          cmd = [
            "*git status*"
            "*git diff*"
            "*git log*"
            "*git show*"
          ];
        };
        action = "allow";
      }
      {
        tool = "mcp__*";
        action = "allow";
      }
      {
        tool = "*";
        action = "ask";
      }
    ];
  };
in
lib.mkIf ampEnabled {
  home.activation.ampConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/amp"

    cat > "$HOME/.config/amp/amp.json" << 'EOF'
    ${ampConfig}
    EOF
  '';
}
