{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  prompts = import ../shared/prompts.nix { };
  opencodeEnabled = values.llm.opencode.enabled or true;
in
lib.mkIf opencodeEnabled {
  xdg.configFile = {
    "opencode/opencode.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";

        share = "disabled";

        theme = common.ui.theme;

        autoupdate = true;

        mcp = common.formatMcpForOpencode mcpServers.servers;

        lsp = common.formatLspForOpencode lsp.lsp;

        agent = prompts.toAgents;
      };
      force = true;
    };
  };
}
