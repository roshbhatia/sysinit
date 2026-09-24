{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };
in
{
  sysinit.llm.managedFiles.strands = {
    path = ".strands/cli/config.json";
    format = "json";
    content = {
      profile = {
        instructions = kit.mkInstructionsWithStyle {
          harness = "strands";
          skillsRoot = "~/.claude/skills";
        };
        mcpServers = llmLib.mcp.formatForCursor (kit.mcpServers.serversFor "strands");
      };
      settings = {
        skillDiscovery = true;
        mcpDiscovery = false;
        telemetry = false;
      };
    };
    enforce = [
      [
        "profile"
        "instructions"
      ]
      [
        "profile"
        "mcpServers"
      ]
      [
        "settings"
        "skillDiscovery"
      ]
      [
        "settings"
        "mcpDiscovery"
      ]
      [
        "settings"
        "telemetry"
      ]
    ];
  };
}
