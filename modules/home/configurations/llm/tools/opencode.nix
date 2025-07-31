{ lib }:
let
  config = import ../config/opencode.nix;
  mcpServers = import ../shared/mcp-servers.nix;
  agents = import ../shared/agents.nix;
in
{
  xdg.configFile = {
    "opencode/opencode.json" = {
      text = builtins.toJSON ({
        "$schema" = config.schema;
        share = "auto";
        theme = config.theme;
        autoupdate = config.autoupdate;
        mcp = {
          hub = {
            type = "remote";
            url = mcpServers.uri;
            enabled = false;
          };
          fetch = {
            type = "local";
            command = [ mcpServers.servers.fetch.command ] ++ mcpServers.servers.fetch.args;
            enabled = true;
          };
          memory = {
            type = "local";
            command = [ mcpServers.servers.memory.command ] ++ mcpServers.servers.memory.args;
            enabled = true;
            environment = mcpServers.servers.memory.env;
          };
          context7 = {
            type = "local";
            command = [ mcpServers.servers.context7.command ] ++ mcpServers.servers.context7.args;
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
  } // builtins.listToAttrs (
    map (agent: {
      name = "opencode/prompts/${agent.name}.nix";
      value = {
        source = toString ../. + "/prompts/${agent.name}.nix";
      };
    }) agents
  );
}
