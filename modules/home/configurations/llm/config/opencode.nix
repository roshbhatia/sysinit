{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit lib values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  prompts = import ../shared/prompts.nix { };
  opencodeEnabled = values.llm.opencode.enabled or true;

  themes = import ../../../../lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  opencodeTheme = themes.getAppTheme "opencode" validatedTheme.colorscheme validatedTheme.variant;

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    share = "disabled";
    theme = opencodeTheme;
    autoupdate = true;
    mcp = common.formatMcpForOpencode mcpServers.servers;
    lsp = common.formatLspForOpencode lsp.lsp;
    agent = prompts.toAgents;
  };
in
lib.mkIf opencodeEnabled {
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/opencode"

    cat > "$HOME/.config/opencode/opencode.json" << 'EOF'
    ${opencodeConfig}
    EOF
  '';
}
