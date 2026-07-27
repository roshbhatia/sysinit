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
    # Amp rejects any skill frontmatter key outside its own allowlist (`effort`
    # is not in it), so it reads the Amp-specific tree written by
    # programs/llm/default.nix instead of ~/.claude/skills.
    "amp.skills.disableClaudeCodeSkills" = true;
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
      text = kit.mkInstructionsWithStyle {
        harness = "amp";
        skillsRoot = "~/.config/amp/skills";
      };
      force = true;
    };
  };
}
