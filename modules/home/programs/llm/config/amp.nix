{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  defaultInstructions = kit.mkInstructions "~/.claude/skills";

  ampConfig = builtins.toJSON {
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
    "amp.updates.mode" = "disabled";
  };
in
{
  xdg.configFile = {
    "amp/settings.json" = {
      text = ampConfig;
      force = true;
    };
    # Amp reads AGENTS.md from project roots and global config paths.
    "amp/AGENTS.md" = {
      text = defaultInstructions;
      force = true;
    };
  };
}
