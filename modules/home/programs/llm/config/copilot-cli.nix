{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  copilotConfig = builtins.toJSON {
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
  home.file = {
    ".copilot/config.json" = {
      text = copilotConfig;
      force = true;
    };
    ".copilot/mcp-config.json" = {
      text = copilotMcpConfig;
      force = true;
    };
  };
}
