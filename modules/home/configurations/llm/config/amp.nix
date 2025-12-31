{
  lib,
  values,
  ...
}:
let
  llmLib = import ../../../../shared/lib/llm { inherit lib; };
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };

  ampConfig = builtins.toJSON {
    "amp.experimental.planMode" = true;
    "amp.git.commit.ampThread.enabled" = false;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = llmLib.formatMcpForAmp mcpServers.servers;
    "amp.permissions" = llmLib.formatPermissionsForAmp llmLib.permissions;
  };
in
{
  xdg.configFile = {
    "amp/settings.json".text = ampConfig;
  };
}
