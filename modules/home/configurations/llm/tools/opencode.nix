_:
let
  config = import ../config/opencode.nix;
  mcpServers = import ../shared/mcp-servers.nix;
in
{
  xdg.configFile = {
    "opencode/opencode.json" = {
      text = builtins.toJSON ({
        "$schema" = config.schema;
        share = "disabled";
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
        };
      });
      force = true;
    };
  };
}
