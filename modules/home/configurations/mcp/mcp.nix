{ ... }:
let
  agents = import ./agents.nix;
  opencodeAgents = builtins.listToAttrs (
    map (agent: {
      name = agent.name;
      value = {
        description = agent.description;
        promptFile = "~/.config/opencode/prompts/${agent.name}.md";
        tags = agent.tags;
        tools = agent.tools;
      };
    }) agents
  );
  promptFiles = builtins.listToAttrs (
    map (agent: {
      name = "opencode/prompts/${agent.name}.md";
      value.source = agent.promptFile;
    }) agents
  );
in
{
  xdg.configFile = promptFiles // {
    "mcphub/servers.json".source = ./mcphub.json;
    "mcphub/servers.json".force = true;
    "goose/config.yaml".source = ./goose.yaml;
    "goose/config.yaml".force = true;
    "goose/.goosehints".source = ./goosehints.md;
    "goose/.goosehints".force = true;
    "opencode/opencode.json".text = builtins.toJSON {
      agent = opencodeAgents;
      # ...other opencode config fields as needed...
    };
    "opencode/opencode.json".force = true;
  };
}
