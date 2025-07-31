{ lib }:
let
  config = import ../config/goose.nix;
  mcpServers = import ../shared/mcp-servers.nix;
in
{
  xdg.configFile."goose/config.yaml" = {
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
}
