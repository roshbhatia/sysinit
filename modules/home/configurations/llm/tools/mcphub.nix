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
        fetch = {
          url = mcpServers.uri;
        };
        memory = {
          url = mcpServers.uri;
        };
        context7 = {
          url = mcpServers.uri;
        };
        argocd-mcp = {
          url = mcpServers.uri;
        };
      };
    };
    force = true;
  };
}
