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
    # Order matters (first match wins): Slack sends ask, destructive commands
    # reject, everything else allows. The reject entries are the shared
    # destructive-deny globs; `reject` is Amp's documented block action.
    "amp.permissions" =
      builtins.map (tool: {
        inherit tool;
        action = "ask";
      }) llmLib.allowlist.slackSendTools
      ++ llmLib.allowlist.formatDestructiveForAmp llmLib.allowlist.destructiveDenyGlobs
      ++ [
        {
          tool = "*";
          action = "allow";
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
