{
  values,
  ...
}:
let
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
in
{
  xdg.configFile."amp/settings.json" = {
    text = ampConfig;
    force = true;
  };
}
