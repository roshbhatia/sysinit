{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  lsp = import ../shared/lsp.nix;
  common = import ../shared/common.nix;
  crushEnabled = values.llm.crush.enabled or false;
in
lib.mkIf crushEnabled {
  xdg.configFile."crush/crush.json" = {
    text = builtins.toJSON {
      "$schema" = "https://charm.land/crush.json";

      lsp = common.formatLspForCrush lsp.lsp;

      inherit (mcpServers) servers;

      permissions = {
        allowed_tools = [
          "view"
          "ls"
          "grep"
          "edit"
          "find"
          "cat"
          "head"
          "tail"
          "diff"
          "mcp_context7_get-library-doc"
          "mcp_fetch_get-page"
          "mcp_git_status"
          "mcp_git_diff"
          "mcp_astgrep_search"
          "mcp_astgrep_rewrite"
          "mcp_astgrep_scan"
        ];

        sandbox = common.permissions.sandbox;
      };

      model = common.defaultModel;

      ui = common.ui;
    };

    force = true;
  };
}
