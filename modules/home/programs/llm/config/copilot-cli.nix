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
    render_markdown = true;
    screen_reader = false;
    theme = "auto";
    trusted_folders = [ ];
    mcpServers = llmLib.mcp.formatForCopilot kit.mcpServers.servers;
  };
in
{
  xdg.configFile = {
    "github-copilot/cli/config.json".text = copilotConfig;
  };
}
