{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  prompts = import ../shared/prompts.nix { };
  directives = import ../shared/directives.nix;

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
    keybinds = {
      leader = "ctrl+f";
    };
    # These are disabled in favor of the serena MCP native tools
    tools = {
      read = false;
      write = false;
      edit = false;
      list = false;
      glob = false;
      grep = false;
    };
    permission = {
      webfetch = "allow";
      bash = common.formatPermissionsForOpencode common.commonShellPermissions;
    };
  };
in
{
  xdg.configFile."opencode/opencode.json" = {
    text = opencodeConfig;
    force = true;
  };
  xdg.configFile."opencode/AGENTS.md" = {
    text = agentsMd;
    force = true;
  };
}
