{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  copilotSettings = {
    banner = "never";
    renderMarkdown = true;
    screenReader = false;
    theme = "auto";
    trusted_folders = [ ];
    autoUpdate = false;
  };

  copilotMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCopilot kit.mcpServers.servers;
  };
in
{

  sysinit.llm.managedFiles.copilot = {
    path = ".copilot/config.json";
    format = "json";
    content = copilotSettings;
  };
  home.file = {
    ".copilot/mcp-config.json" = {
      text = copilotMcpConfig;
      force = true;
    };

    ".copilot/copilot-instructions.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "copilot";
        skillsRoot = "~/.copilot/skills";
      };
      force = true;
    };
  };
}
