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
          "find"
          "cat"
          "head"
          "tail"
          "diff"
          "mcp_context7_get-library-doc"
          "mcp_fetch_get-page"
          "mcp_git_status"
          "mcp_git_diff"
          "mcp_chroma_query"
        ];

        sandbox = {
          enabled = true;
          allow_network = true;
          allow_file_write = true;
        };
      };

      model = {
        provider = "anthropic";
        name = "claude-3-5-sonnet";
        temperature = 0.7;
        max_tokens = 8192;
      };

      ui = {
        theme = "system";
        auto_format = true;
        syntax_highlighting = true;
      };

    };

    force = true;
  };
}
