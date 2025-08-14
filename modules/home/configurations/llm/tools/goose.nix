{ lib, values, ... }:
let
  gooseProvider = values.llm.goose.provider or "github_copilot";

  providerConfigs = {
    "github_copilot" = {
      model = "gemini-2.0-flash-001";
      plannerModel = "claude-3.7-sonnet";
      provider = "github_copilot";
    };
    "claude-code" = {
      model = "claude-3-5-sonnet-20241022";
      plannerModel = "claude-3-5-sonnet-20241022";
      provider = "claude-code";
    };
  };

  config = (providerConfigs.${gooseProvider} or providerConfigs.github_copilot) // {
    editMode = "vi";
  };

  agents = import ../shared/agents.nix;

  toTitleCase =
    name:
    let
      words = lib.splitString "-" name;
      capitalizeWord =
        word: lib.toUpper (lib.substring 0 1 word) + lib.substring 1 (lib.stringLength word) word;
    in
    lib.concatStringsSep " " (map capitalizeWord words);

  activitiesToYaml =
    activities: lib.concatStringsSep "\n" (map (activity: "  - \"${activity}\"") activities);
in
{
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        EDIT_MODE = config.editMode;
        GOOSE_MODEL = config.model;
        GOOSE_PLANNER_MODEL = config.plannerModel;
        GOOSE_PROVIDER = config.provider;
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
      name = "goose/recipes/${agent.name}/recipe.yaml";
      value = {
        text = ''
          version: 1.0.0
          title: ${toTitleCase agent.name}
          description: ${agent.description}
          instructions: |
            ${agent.prompt}

          activities:
          ${activitiesToYaml agent.activities}
        '';
      };
    }) agents
  );
}
