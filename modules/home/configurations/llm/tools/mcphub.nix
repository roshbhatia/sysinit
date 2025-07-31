{
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix;
in
{
  xdg.configFile."mcphub/servers.json" = {
    text = builtins.toJSON {
      mcpServers = mcpServers.servers;
    };
    force = true;
  };
}

