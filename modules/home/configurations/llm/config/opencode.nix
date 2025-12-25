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
    autoupdate = false;
    share = "disabled";
    theme = "system";

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
in
{
  home.activation = {
    opencodeConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeConfigFile.script;
    opencodeAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] opencodeAgentsFile.script;
  };
}
