{ lib, ... }:
let
  config = import ../config/goose.nix;
  agents = import ../shared/agents.nix;
in
{
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        ALPHA_FEATURES = true;
        EDIT_MODE = config.editMode;
        GOOSE_PROVIDER = config.provider;
        extensions = config.extensions;
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
