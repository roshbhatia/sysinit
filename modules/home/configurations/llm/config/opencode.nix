{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  directives = import ../shared/directives.nix;
  prompts = import ../shared/prompts.nix { };

  themes = import ../../../../shared/lib/theme { inherit lib; };

  validatedTheme = values.theme;
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
    autoupdate = false;

    mcp = common.formatMcpForOpencode mcpServers.servers;
    lsp = common.formatLspForOpencode lsp.lsp;

    agent = prompts.toAgents;
    inherit instructions;

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
    };

    # plugin = [
    #   "@tarquinen/opencode-dcp@latest"
    # ];
    #
    # experimental = {
    #   primary_tools = [ "prune" ];
    # };
  };

  opencodeConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "opencode/opencode.json";
    text = opencodeConfig;
    force = false;
  };

  opencodeAgentsFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "opencode/AGENTS.md";
    text = agentsMd;
    force = false;
  };

  # openagentsSrc = pkgs.fetchFromGitHub {
  #   owner = "darrenhinde";
  #   repo = "OpenAgents";
  #   rev = "bad7b8f58a5f36a8bfa89663781c4337303d5677";
  #   sha256 = "1pjfbncq6n43y5f0xqs9pq3mn1z75aad75fgg0nhjxp6dkjsjfpy";
  # };
in
{
  home.activation = {
    opencodeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeConfigFile.script;
    opencodeAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeAgentsFile.script;
  };

  # xdg.configFile."opencode/agent".source = "${openagentsSrc}/.opencode/agent";
  # xdg.configFile."opencode/command".source = "${openagentsSrc}/.opencode/command";
  # xdg.configFile."opencode/context".source = "${openagentsSrc}/.opencode/context";
  # xdg.configFile."opencode/plugin".source = "${openagentsSrc}/.opencode/plugin";
  # xdg.configFile."opencode/prompts".source = "${openagentsSrc}/.opencode/prompts";
  # xdg.configFile."opencode/tool".source = "${openagentsSrc}/.opencode/tool";
}
