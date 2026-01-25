{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  cfg = values.llm.copilot or { };

  formatMcpForCopilot =
    mcpServers:
    builtins.mapAttrs (_name: server: {
      type = "stdio";
      inherit (server) command;
      inherit (server) args;
    }) mcpServers;

  copilotConfig = builtins.toJSON {
    banner = cfg.banner or "never";
    render_markdown = cfg.renderMarkdown or true;
    screen_reader = cfg.screenReader or false;
    theme = cfg.theme or "auto";
    trusted_folders = cfg.trustedFolders or [ ];
    mcpServers = formatMcpForCopilot mcpServers.servers;
  };
in
{
  xdg.configFile = {
    "github-copilot/cli/config.json".text = copilotConfig;
  };
}
