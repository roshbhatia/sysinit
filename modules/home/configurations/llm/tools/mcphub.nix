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
          command = [ mcpServers.servers.fetch.command ] ++ mcpServers.servers.fetch.args;
        };
        memory = {
          command = [ mcpServers.servers.memory.command ] ++ mcpServers.servers.memory.args;
          env = mcpServers.servers.memory.env;
        };
        context7 = {
          command = [ mcpServers.servers.context7.command ] ++ mcpServers.servers.context7.args;
        };
        argocd-mcp = {
          command = [ mcpServers.servers.argocd-mcp.command ] ++ mcpServers.servers.argocd-mcp.args;
        };
      };
    };
    force = true;
  };
}

