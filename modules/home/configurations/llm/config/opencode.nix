{
  lib,
  values,
  ...
}:
let
  llmLib = import ../../../../shared/lib/llm { inherit lib; };
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  subagents = import ../shared/subagents;
  lsp = import ../shared/lsp.nix;
  directives = import ../shared/directives.nix;

  additionalAgents = values.llm.opencode.agents or { };
  agents = subagents // additionalAgents;

  opencodeConfigJson = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";
    mcp = llmLib.formatMcpForOpencode mcpServers.servers;
    lsp = llmLib.formatLspForOpencode lsp.lsp;
    agent = agents;
    instructions = [
      "**/CONTRIBUTING.md"
      "**/docs/guidelines.md"
      "**/.cursor/rules/*.md"
      "**/COPILOT.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
    ];
    keybinds = {
      leader = "ctrl+a";
    };
    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
      skill = {
        "*" = "allow";
      };
    };
  };

  agentsMd = ''
    ${directives.general}
  '';

in
{
  xdg.configFile = {
    "opencode/opencode.json".text = opencodeConfigJson;
    "opencode/AGENTS.md".text = agentsMd;
  };

  xdg.configFile = builtins.mapAttrs (skillName: _skillMeta: {
    name = "opencode/skills/" + skillName;
    source = ../shared/skills/. + skillName;
    recursive = true;
  }) (import ../shared/skills).metadata;
}
