{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Keep this list for confirmed per-harness incompatibilities only.
  disabledMcpServers = [ "slack" ];

  # The schemas ship inside the installed derivation, so a version bump moves
  # the binary and its schema together and a key move fails validation on the
  # bump itself. Do not vendor a copy: it would need its own drift check.
  schemaDir = "${render.schemas}";

  # Skills install only to ~/.claude/skills (per default.nix); opencode reads
  # that tree natively. Point instructions at the populated root, not a phantom
  # per-tool dir that holds no SKILL.md files.
  defaultInstructions =
    kit.mkInstructions {
      harness = "opencode";
      skillsRoot = "~/.claude/skills";
    }
    + ''

      ## OpenCode-specific Slack access

      OpenCode's MCP client does not support Slack's dynamic auth flow. If you
      need Slack context or need to send a Slack message, ask Claude Code to do
      it with `claude -p '<your Slack task>'` because Claude has Slack MCP
      access configured.
    ''
    + "\n## Output Style\n\n"
    + kit.llmLib.instructions.outputStyleRules;

  render = import ./opencode-render.nix { inherit pkgs lib; };

  opencodeConfig = render.main // {
    mcp = llmLib.mcp.formatForOpencode disabledMcpServers kit.mcpServers.servers;

  };

  subagentFiles = lib.mapAttrs' (
    name: agentConfig:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
        harness = "opencode";
      };
    }
  ) llmLib.instructions.subagentDefs;

in
{
  # OpenCode writes plugin installation state back into opencode.json on first
  # startup, so neither file can be a store symlink. OpenCode 1.18 moved the
  # terminal settings into tui.json and made opencode.json reject unknown keys
  # (`additionalProperties: false` on the Config definition), so the two files
  # are declared and validated separately.
  sysinit.llm.managedFiles = {
    opencode = {
      path = ".config/opencode/opencode.json";
      format = "json";
      content = opencodeConfig;
      schema = "${schemaDir}/config.json";
      inherit (render) enforce retire;
    };
    opencode-tui = {
      path = ".config/opencode/tui.json";
      format = "json";
      content = render.tui;
      schema = "${schemaDir}/tui.json";
      retire = render.retiredTui;
    };
  };

  xdg.configFile = lib.mkMerge [
    {
      "opencode/plugin/sysinit-notify.ts" = {
        source = ./plugins/sysinit-notify.ts;
        force = true;
      };
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];

  home.packages = [ pkgs.opencode ];
}
