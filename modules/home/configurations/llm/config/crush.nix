{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp.nix { inherit lib values; };
  lspConfig = (import ../shared/lsp.nix).lsp;
  directives = import ../shared/directives.nix;

  agentsMd = ''
    ${directives.general}
  '';

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

  formatLspForCrush =
    lspCfg:
    builtins.mapAttrs (
      _name: lspCfg:
      if lspCfg ? command then
        {
          command = if builtins.isList lspCfg.command then builtins.head lspCfg.command else lspCfg.command;
          enabled = true;
        }
      else
        {
          enabled = false;
        }
    ) lspCfg;

  crushSettings = {
    lsp = formatLspForCrush lspConfig;
    mcp = formatMcpForCrush mcpServers.servers;
  };

  crushConfig = builtins.toJSON crushSettings;

in
{
  xdg.configFile = {
    "crush/crush.json".text = crushConfig;
    "crush/AGENTS.md".text = agentsMd;
  };
}
