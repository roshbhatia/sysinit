{
  schema = "https://charm.land/crush.json";

  lsp = {
    go = {
      command = "gopls";
    };
    typescript = {
      command = "typescript-language-server";
      args = [ "--stdio" ];
    };
    nix = {
      command = "nil";
    };
    lua = {
      command = "lua-language-server";
      args = [ "--stdio" ];
    };
    python = {
      command = "pyright-langserver";
      args = [ "--stdio" ];
    };
    json = {
      command = "json-language-server";
      args = [ "--stdio" ];
    };
    yaml = {
      command = "yaml-language-server";
      args = [ "--stdio" ];
    };
    dockerfile = {
      command = "docker-langserver";
      args = [ "--stdio" ];
    };
    terraform = {
      command = "terraform-language-server";
      args = [ "serve" ];
    };
  };

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
