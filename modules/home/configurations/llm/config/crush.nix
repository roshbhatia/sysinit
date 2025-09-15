{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  lsp = import ../shared/lsp.nix;
  crushEnabled = values.llm.crush.enabled or false;
in
lib.mkIf crushEnabled {
  xdg.configFile."crush/crush.json" = {
    text = builtins.toJSON {
      "$schema" = "https://charm.land/crush.json";
      lsp = builtins.mapAttrs (_name: lsp: {
        command =
          if builtins.length lsp.command == 1 then
            builtins.elemAt lsp.command 0
          else
            builtins.elemAt lsp.command 0;
        args = lsp.args or null;
        env = lsp.env or null;
      }) lsp.lsp;
      inherit (mcpServers) servers;
      permissions = {
        allowed_tools = [
          "view"
          "ls"
          "grep"
          "edit"
          "mcp_context7_get-library-doc"
        ];
      };
    };
    force = true;
  };
}
