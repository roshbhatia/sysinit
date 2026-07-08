{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  ampConfig = builtins.toJSON {
    "amp.experimental.planMode" = true;
    "amp.git.commit.ampThread.enabled" = false;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = llmLib.mcp.formatForAmp kit.mcpServers.servers;
    "amp.permissions" = llmLib.allowlist.formatForAmp llmLib.allowlist.tierA ++ [
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
  xdg.configFile = {
    "amp/settings.json".text = ampConfig;
  };
}
