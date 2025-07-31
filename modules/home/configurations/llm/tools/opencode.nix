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
          Hub = {
            type = "remote";
            url = mcpServers.uri;
            enabled = true;
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
