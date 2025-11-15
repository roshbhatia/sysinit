{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  gooseEnabled = values.llm.goose.enabled or true;

  gooseConfig = lib.generators.toYAML { } {
    ALPHA_FEATURES = true;
    EDIT_MODE = "vi";
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";

    extensions = common.gooseBuiltinExtensions // (common.formatMcpForGoose lib mcpServers.servers);
  };
in
lib.mkIf gooseEnabled {
  home.activation.gooseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/goose"

    cat > "$HOME/.config/goose/config.yaml" << 'EOF'
    ${gooseConfig}
    EOF
  '';
}
