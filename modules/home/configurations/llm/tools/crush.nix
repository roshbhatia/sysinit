{ lib }:
let
  config = import ../config/crush.nix;
  mcpServers = import ../shared/mcp-servers.nix;
in
{
  xdg.configFile."crush/crush.json" = {
    text = builtins.toJSON {
      "$schema" = config.schema;
      lsp = config.lsp;
      mcp = {
        fetch = {
          type = "stdio";
          command = mcpServers.servers.fetch.command;
          args = mcpServers.servers.fetch.args;
        };
        memory = {
          type = "stdio";
          command = mcpServers.servers.memory.command;
          args = mcpServers.servers.memory.args;
          env = mcpServers.servers.memory.env;
        };
        context7 = {
          type = "stdio";
          command = mcpServers.servers.context7.command;
          args = mcpServers.servers.context7.args;
        };
      };
      permissions = config.permissions;
    };
    force = true;
  };
}
