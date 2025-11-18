{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  prompts = import ../shared/prompts.nix { };
  directives = import ../shared/directives.nix;
  opencodeEnabled = values.llm.opencode.enabled or true;

  themes = import ../../../../lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  opencodeTheme = themes.getAppTheme "opencode" validatedTheme.colorscheme validatedTheme.variant;

  defaultInstructions = [
    "**/CONTRIBUTING.md"
    "**/docs/guidelines.md"
    "**/.cursor/rules/*.md"
    "**/COPILOT.md"
    "**/CLAUDE.md"
    "**/CONSTITUTION.md"
  ];

  agentsMd = ''
    ${directives.general}
  '';

  instructions = values.llm.opencode.instructions or defaultInstructions;

  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    share = "disabled";
    theme = opencodeTheme;
    autoupdate = true;
    mcp = common.formatMcpForOpencode mcpServers.servers;
    lsp = common.formatLspForOpencode lsp.lsp;
    agent = prompts.toAgents;
    instructions = instructions;
  };
in
lib.mkIf opencodeEnabled {
  home.activation = {
    opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/opencode"

      cat > "$HOME/.config/opencode/opencode.json" << 'EOF'
      ${opencodeConfig}
      EOF
    '';

    opencodeAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.config/opencode"

      cat > "$HOME/.config/opencode/AGENTS.md" << 'EOF'
      ${agentsMd}
      EOF
    '';
  };
}
