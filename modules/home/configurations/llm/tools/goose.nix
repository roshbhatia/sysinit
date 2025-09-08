{ lib, ... }:
let
  config = import ../config/goose.nix;
  agents = import ../shared/agents.nix;
in
{
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        EDIT_MODE = config.editMode;
        GOOSE_MODEL = config.model;
        GOOSE_PLANNER_MODEL = config.plannerModel;
        GOOSE_PROVIDER = config.provider;
        extensions = config.extensions;
      };
      force = true;
    };
  }
  // builtins.listToAttrs (
    map (agent: {
      name = "goose/recipes/${agent.name}/recipe.yaml";
      value = {
        text = ''
          version: 1.0.0
          title: ${agent.name}
          description: ${agent.description}
          instructions: |
            <prompt>
            ${agent.prompt}
            </prompt>

          activities:
          ${lib.concatStringsSep "\n" (map (activity: "  - \"${activity}\"") agent.activities)}
        '';
      };
    }) agents
  );
}
