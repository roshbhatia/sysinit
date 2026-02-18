{
  lib,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix {
    inherit lib;
    additionalServers = config.sysinit.llm.mcp.additionalServers;
  };

  copilotConfig = builtins.toJSON {
    banner = "never";
    render_markdown = true;
    screen_reader = false;
    theme = "auto";
    trusted_folders = [ ];
    mcpServers = llmLib.mcp.formatForCopilot mcpServers.servers;
  };
in
{
  xdg.configFile = {
    "github-copilot/cli/config.json".text = copilotConfig;
  };
}
