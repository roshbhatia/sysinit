{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../mcp.nix { inherit lib values; };

  formatMcpForAmp =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          inherit (server) url;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
          env = server.env or { };
        }
    ) mcpServers;

  formatPermissionsForAmp = _perms: [
    {
      tool = "Bash";
      matches = {
        cmd = "*git commit*";
      };
      action = "ask";
    }
    {
      tool = "Bash";
      matches = {
        cmd = [
          "*git status*"
          "*git diff*"
          "*git log*"
          "*git show*"
        ];
      };
      action = "allow";
    }
    {
      tool = "mcp__*";
      action = "allow";
    }
    {
      tool = "*";
      action = "ask";
    }
  ];

  ampConfig = builtins.toJSON {
    "amp.experimental.planMode" = true;
    "amp.git.commit.ampThread.enabled" = false;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = formatMcpForAmp mcpServers.servers;
    "amp.permissions" = formatPermissionsForAmp mcpServers.allPermissions;
  };
in
{
  xdg.configFile = {
    "amp/settings.json".text = ampConfig;
  };
}
