{ }:
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
          fetch = {
            type = "local";
            enabled = true;
            command = [ mcpServers.servers.fetch.command ] ++ mcpServers.servers.fetch.args;
          };
          memory = {
            type = "local";
            enabled = true;
            environment = mcpServers.servers.memory.env;
            command = [ mcpServers.servers.memory.command ] ++ mcpServers.servers.memory.args;
          };
          context7 = {
            type = "local";
            enabled = true;
            command = [ mcpServers.servers.context7.command ] ++ mcpServers.servers.context7.args;
          };
        };
        agent = builtins.listToAttrs (
          map (agent: {
            name = agent.name;
            value = {
              description = agent.description;
              prompt = agent.prompt;
            };
          }) agents
        );
      });
      force = true;
    };
  }
  // builtins.listToAttrs (
    map (agent: {
      name = "opencode/prompts/${agent.name}.nix";
      value = {
        source = toString ../. + "/prompts/${agent.name}.nix";
      };
    }) agents
  );
}
