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
    # amp uses glob-on-cmd matching; the canonical allowlist (Tier A) uses
    # exact + trailing-`*` prefix patterns with different semantics. Keep
    # amp's explicit permissions inline until a glob-aware formatter exists.
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
  xdg.configFile = {
    "amp/settings.json".text = ampConfig;
  };
}
