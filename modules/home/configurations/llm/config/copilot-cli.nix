{
  lib,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  cfg = values.llm.copilot or { };

  copilotConfig = builtins.toJSON {
    banner = cfg.banner or "never";
    render_markdown = cfg.renderMarkdown or true;
    screen_reader = cfg.screenReader or false;
    theme = cfg.theme or "auto";
    trusted_folders = cfg.trustedFolders or [ ];
    mcpServers = llmLib.mcp.formatForCopilot mcpServers.servers;
  };
in
{
  xdg.configFile = {
    "github-copilot/cli/config.json".text = copilotConfig;
  };
}
