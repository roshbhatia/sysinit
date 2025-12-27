{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  lspConfig = (import ../shared/lsp.nix).lsp;
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  directives = import ../shared/directives.nix;

  # Convert LSP config to Crush format
  formatLspForCrush =
    lspCfg:
    builtins.mapAttrs (
      _name: lsp:
      if lsp ? command then
        {
          command = if builtins.isList lsp.command then builtins.head lsp.command else lsp.command;
          enabled = true;
        }
      else
        {
          enabled = false;
        }
    ) lspCfg;

  # Convert MCP servers to Crush format - simplified
  formatMcpForCrush =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
        }
      else
        {
          type = "stdio";
          inherit (server) command;
          args = server.args or [ ];
        }
    ) mcpServers;

  agentsMd = ''
    ${directives.general}
  '';

  crushSettings = {
    lsp = formatLspForCrush lspConfig;
    mcp = formatMcpForCrush mcpServers.servers;
  };

  crushConfig = builtins.toJSON crushSettings;

  # Create writable config files
  crushConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "crush/crush.json";
    text = crushConfig;
    force = false;
  };

  crushAgentsFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "crush/AGENTS.md";
    text = agentsMd;
    force = false;
  };
in
{
  home.activation = {
    crushConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] crushConfigFile.script;
    crushAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] crushAgentsFile.script;
  };
}
