{ lib, ... }:
let
  config = import ./config.nix;
  agents = import ./agents.nix;
  promptFiles = builtins.listToAttrs (
    map (agent: {
      name = "opencode/prompts/${agent.name}.nix";
      value = {
        source = toString ./. + "/prompts/${agent.name}.nix";
      };
    }) agents
  );
in
{
  xdg.configFile = promptFiles // {
    "mcphub/servers.json" = {
      text = builtins.toJSON {
        mcpServers = {
          fetch = {
            command = [ config.mcphub.servers.fetch.command ] ++ config.mcphub.servers.fetch.args;
          };
          memory = {
            command = [ config.mcphub.servers.memory.command ] ++ config.mcphub.servers.memory.args;
            env = config.mcphub.servers.memory.env;
          };
          context7 = {
            command = [ config.mcphub.servers.context7.command ] ++ config.mcphub.servers.context7.args;
          };
          argocd-mcp = {
            command = [ config.mcphub.servers.argocd-mcp.command ] ++ config.mcphub.servers.argocd-mcp.args;
          };
        };
      };
      force = true;
    };
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        EDIT_MODE = config.goose.editMode;
        GOOSE_MODEL = config.goose.model;
        GOOSE_PLANNER_MODEL = config.goose.plannerModel;
        GOOSE_PROVIDER = config.goose.provider;
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
            uri = config.mcphub.uri;
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
    "goose/.goosehints" = {
      source = ./goosehints.md;
      force = true;
    };
    "opencode/opencode.json" = {
      text = builtins.toJSON ({
        "$schema" = config.opencode.schema;
        share = "auto";
        theme = config.opencode.theme;
        autoupdate = config.opencode.autoupdate;
        mcp = {
          hub = {
            type = "remote";
            url = config.mcphub.uri;
            enabled = false;
          };
          fetch = {
            type = "local";
            command = [ config.mcphub.servers.fetch.command ] ++ config.mcphub.servers.fetch.args;
            enabled = true;
          };
          memory = {
            type = "local";
            command = [ config.mcphub.servers.memory.command ] ++ config.mcphub.servers.memory.args;
            enabled = true;
            environment = config.mcphub.servers.memory.env;
          };
          context7 = {
            type = "local";
            command = [ config.mcphub.servers.context7.command ] ++ config.mcphub.servers.context7.args;
            enabled = true;
          };
        };
        agent = builtins.listToAttrs (
          map (agent: {
            name = agent.name;
            value = {
              description = agent.description;
              prompt = agent.prompt;
              tools = agent.tools;
            };
          }) agents
        );
      });
      force = true;
    };
  };
}
