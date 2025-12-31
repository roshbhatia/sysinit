{
  lib,
  values,
  ...
}:
let
  llmLib = import ../../../../shared/lib/llm { inherit lib; };
  lspConfig = (import ../shared/lsp.nix).lsp;
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  directives = import ../shared/directives.nix;

  agentsMd = ''
    ${directives.general}
  '';

  crushSettings = {
    lsp = llmLib.formatLspForCrush lspConfig;
    mcp = llmLib.formatMcpForCrush mcpServers.servers;
  };

  crushConfig = builtins.toJSON crushSettings;
in
{
  xdg.configFile = {
    "crush/crush.json".text = crushConfig;
    "crush/AGENTS.md".text = agentsMd;
  };
}
