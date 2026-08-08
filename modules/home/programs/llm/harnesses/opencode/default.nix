{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  disabledMcpServers = [ "slack" ];

  schemaDir = "${render.schemas}";

  defaultInstructions =
    kit.mkInstructions {
      harness = "opencode";
      skillsRoot = "~/.claude/skills";
    }
    + ''


      OpenCode's MCP client does not support Slack's dynamic auth flow. If you
      need Slack context or need to send a Slack message, ask Claude Code to do
      it with `claude -p '<your Slack task>'` because Claude has Slack MCP
      access configured.
    ''
    + "\n## Output Style\n\n"
    + kit.llmLib.instructions.outputStyleRules;

  render = import ./render.nix { inherit pkgs lib; };

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
