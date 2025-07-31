{ lib }:
let
  config = import ../config/goose.nix;
  mcpServers = import ../shared/mcp-servers.nix;
  agents = import ../shared/agents.nix;

  # Helper function to convert agent name to title case
  toTitleCase = name:
    let
      words = lib.splitString "-" name;
      capitalizeWord = word:
        lib.toUpper (lib.substring 0 1 word) + lib.substring 1 (lib.stringLength word) word;
    in
    lib.concatStringsSep " " (map capitalizeWord words);

  # Helper function to convert activities list to YAML
  activitiesToYaml = activities:
    lib.concatStringsSep "\n" (map (activity: "  - \"${activity}\"") activities);
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
          hub = {
            uri = mcpServers.uri;
            bundled = false;
            description = "Hub for various mcp servers";
            enabled = true;
            name = "Hub";
            timeout = 300;
            type = "streamable_http";
          };
        };
      };
      force = true;
    };
  } // builtins.listToAttrs (
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

