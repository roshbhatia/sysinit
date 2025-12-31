{
  lib,
  values,
  ...
}:
let
  cfg = values.llm.copilot or { };

  copilotConfig = builtins.toJSON {
    banner = cfg.banner or "never";
    render_markdown = cfg.renderMarkdown or true;
    screen_reader = cfg.screenReader or false;
    theme = cfg.theme or "auto";
    trusted_folders = cfg.trustedFolders or [ ];
  };

  mcpConfig = builtins.toJSON {
    mcpServers = { };
  };
in
{
  xdg.configFile = {
    "github-copilot/cli/config.json".text = copilotConfig;
    "github-copilot/cli/mcp-config.json".text = mcpConfig;
  };
}
