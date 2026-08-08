{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  ampSettings = {
    "amp.git.commit.ampThread.enabled" = false;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = llmLib.mcp.formatForAmp kit.mcpServers.servers;
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
    "amp.skills.disableClaudeCodeSkills" = true;
  };
in
{

  sysinit.llm.managedFiles.amp = {
    path = ".config/amp/settings.json";
    format = "json";
    content = ampSettings;
    enforce = [
      "amp.permissions"
    ];
  };
  xdg.configFile = {
    "amp/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "amp";
        skillsRoot = "~/.config/amp/skills";
      };
      force = true;
    };
  };
}
