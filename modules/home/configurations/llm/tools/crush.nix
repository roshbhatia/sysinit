{
  ...
}:
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
        fetch = { url = mcpServers.uri; };
        memory = { url = mcpServers.uri; };
        context7 = { url = mcpServers.uri; };
      };
      permissions = config.permissions;
    };
    force = true;
  };
}
