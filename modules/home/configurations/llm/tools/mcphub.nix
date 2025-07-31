{
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix;
in
{
  xdg.configFile."mcphub/servers.json" = {
    text = builtins.toJSON {
      mcpServers = {
        fetch = mcpServers.fetch;
        memory = mcpServers.memory;
        context7 = mcpServers.context7;
      };
    };
    force = true;
  };
}

