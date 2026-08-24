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

  remoteExecutionDenyGlobs = [
    "amp orb*"
    "amp * orb*"
  ];

  ampSettings = {
    "amp.git.commit.ampThread.enabled" = false;
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

    "amp.remoteThreadCreation.enabled" = remoteExecution;

    "amp.updates.mode" = "disabled";
    "amp.skills.disableClaudeCodeSkills" = true;
  };

  ampEnforced = builtins.attrNames ampSettings;
in
{

  sysinit.llm.managedFiles.amp = {
    path = ".config/amp/settings.json";
    format = "json";
    content = ampSettings;
    enforce = ampEnforced;
  };
  # amp gates its OTLP export on this variable alone and offers no config key
  # for it. The endpoint comes from otel-collector.nix, and amp's SDK defaults
  # to http/protobuf, which the collector's receiver takes.
  #
  # It exports traces only: the NodeSDK is built with no metric reader and no
  # log processor. Its root span `main` ends inside a process exit handler,
  # after the last batch flush, so reel usually never receives it and draws the
  # fetch spans under a synthesized turn instead.
  home.sessionVariables.AMP_ENABLE_TRACING = "1";

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
