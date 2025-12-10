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
  directives = import ../shared/directives.nix { };
  prompts = import ../shared/prompts.nix { };
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

  instructions = defaultInstructions;

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
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
    };

    plugin = [
      "@tarquinen/opencode-dcp@latest"
    ];

    experimental = {
      primary_tools = [ "prune" ];
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
rec {
  openagentsSrc = pkgs.fetchFromGitHub {
    owner = "darrenhinde";
    repo = "OpenAgents";
    rev = "bad7b8f58a5f36a8bfa89663781c4337303d5677";
    sha256 = "1pjfbncq6n43y5f0xqs9pq3mn1z75aad75fgg0nhjxp6dkjsjfpy";
  };

  home.activation = {
    opencodeConfig = opencodeConfigFile.activation;
    opencodeAgents = opencodeAgentsFile.activation;
  };

  home.file.".opencode/agent/openagent.md" = {
    source = "${openagentsSrc}/.opencode/agent/openagent.md";
  };
}
