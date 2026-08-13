{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  inherit (config.sysinit.llm.amp) remoteExecution;

  # `amp orb` is a whole command tree, so one glob covers every subcommand.
  remoteExecutionDenyGlobs = [
    "amp orb*"
    "amp * orb*"
  ];

  ampSettings = {
    "amp.git.commit.ampThread.enabled" = false;
    "amp.git.commit.coauthor.enabled" = false;
    "amp.mcpServers" = llmLib.mcp.formatForAmp kit.mcpServers.servers;
    "amp.permissions" =
      builtins.map (tool: {
        inherit tool;
        action = "ask";
      }) llmLib.allowlist.slackSendTools
      ++ llmLib.allowlist.formatDestructiveForAmp (
        llmLib.allowlist.destructiveDenyGlobs ++ lib.optionals (!remoteExecution) remoteExecutionDenyGlobs
      )
      ++ [
        {
          tool = "*";
          action = "allow";
        }
      ];

    # Amp's own read of this key is "let ampcode.com create new threads that open
    # in the interactive Amp TUI on this machine". Declared rather than left to
    # amp's default so the posture is visible in the file the owner reads.
    "amp.remoteThreadCreation.enabled" = remoteExecution;

    "amp.updates.mode" = "disabled";
    "amp.skills.disableClaudeCodeSkills" = true;
  };

  # Every key, not `amp.permissions` alone.
  ampEnforced = builtins.attrNames ampSettings;
in
{

  sysinit.llm.managedFiles.amp = {
    path = ".config/amp/settings.json";
    format = "json";
    content = ampSettings;
    enforce = ampEnforced;
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
