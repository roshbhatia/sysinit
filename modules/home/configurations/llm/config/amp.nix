{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };

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

  ampConfig = builtins.toJSON {
    "amp.git.commit.ampThread.enabled" = false;
    "amp.experimental.planMode" = true;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = formatMcpForAmp mcpServers.servers;
    "amp.permissions" = [
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
  };

  ampConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "amp/settings.json";
    text = ampConfig;
  };
in
{
  home.activation = {
    ampConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ampConfigFile.script;
  };
}
