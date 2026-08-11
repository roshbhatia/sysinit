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

  # `amp orb` is a whole command tree, so one glob covers every subcommand. The
  # matching entry for the settings side is `amp.remoteThreadCreation.enabled`
  # below: together they close the two ways a thread leaves this machine, an
  # agent starting an orb and ampcode.com opening a thread here.
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

  # Every key, not `amp.permissions` alone. A merge preserves whatever amp last
  # wrote for a key whose value this repository states outright, so before this
  # the other five drifted silently: `amp mcp add` would survive a switch, and so
  # would amp turning update checking back on.
  #
  # `amp.mcpServers` is safe to enforce because the Nix value is the complete set
  # for this host. That is the opposite of goose's `extensions`, where the file
  # holds live servers Nix never declared and enforcing the parent would delete
  # them.
  #
  # Nothing here is an owner runtime preference. Amp writes its theme, model, and
  # thread state elsewhere, not into settings.json.
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
