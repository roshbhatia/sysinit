{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  agents = import ../shared/agents.nix;
  gooseEnabled = values.llm.goose.enabled or false;
in
lib.mkIf gooseEnabled {
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        ALPHA_FEATURES = true;
        EDIT_MODE = "vi";
        GOOSE_PROVIDER = values.llm.goose.provider;
        GOOSE_LEAD_MODEL = values.llm.goose.leadModel;
        GOOSE_MODEL = values.llm.goose.model;
        inherit (mcpServers) servers;
        extensions = {
          computercontroller = {
            bundled = true;
            display_name = "Computer Controller";
            enabled = true;
            name = "computercontroller";
            timeout = 300;
            type = "builtin";
          };
          developer = {
            bundled = true;
            display_name = "Developer Tools";
            enabled = true;
            name = "developer";
            timeout = 300;
            type = "builtin";
            args = null;
          };
        };
      };
      force = true;
    };
  }
  // builtins.listToAttrs (
    map (agent: {
      name = "goose/subagents/${agent.name}.yaml";
      value = {
        text = lib.generators.toYAML { } {
          id = agent.name;
          title = agent.name;
          description = agent.description;
          instructions = agent.instructions or "";
          activities = agent.activities or [ ];
          extensions = agent.extensions or [ ];
          parameters = agent.parameters or [ ];
          prompt = agent.prompt or "";
        };
      };
    }) agents
  );
}
