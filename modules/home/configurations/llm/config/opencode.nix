{
  lib,
  pkgs,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  prompts = import ../shared/prompts.nix { };
  directives = import ../shared/directives.nix;
  writableConfigs = import ../shared/writable-configs.nix { inherit lib pkgs; };

  themes = import ../../../../shared/lib/theme { inherit lib; };

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
      leader = "ctrl+j";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
    };
  };

  opencodeConfigFile = writableConfigs.mkWritableConfig {
    path = "opencode/opencode.json";
    text = opencodeConfig;
    force = false;
  };

  opencodeAgentsFile = writableConfigs.mkWritableConfig {
    path = "opencode/AGENTS.md";
    text = agentsMd;
    force = false;
  };
in
{
  home.activation = {
    opencodeConfig = opencodeConfigFile.activation;
    opencodeAgents = opencodeAgentsFile.activation;
  };
}
