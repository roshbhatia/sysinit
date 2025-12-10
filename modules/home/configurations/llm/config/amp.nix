{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  inherit (lib) mkIf;
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;

  ampConfig = builtins.toJSON {
    "amp.git.commit.ampThread.enabled" = false;
    "amp.experimental.planMode" = true;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = common.formatMcpForAmp mcpServers.servers;
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

  # Create writable config file
  ampConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "amp/settings.json";
    text = ampConfig;
    force = false; # Preserve user edits when source unchanged
  };
in
{
  home.activation = mkIf values.llm.agents.amp {
    ampConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ampConfigFile.script;
  };
}
