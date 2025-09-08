{
  schema = "https://charm.land/crush.json";

  lsp = import ../shared/lsp.nix;

  permissions = {
    allowed_tools = [
      "view"
      "ls"
      "grep"
      "edit"
      "mcp_context7_get-library-doc"
    ];
  };
}
