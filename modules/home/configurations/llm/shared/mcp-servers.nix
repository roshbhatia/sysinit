{
  values,
}:

let
  defaultServers = {
    astgrep = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/ast-grep/ast-grep-mcp"
        "ast-grep-server"
      ];
      description = "Structural code search and refactoring with ast-grep. Provides AST-based pattern matching for semantic code search across multiple languages.";
    };
    neovim = {
      command = "npx";
      args = [
        "-y"
        "mcp-neovim-server"
      ];
      # Socket path will be set by neovim RPC module via NVIM_SOCKET_PATH env var in tmux sessions
      # This env block ensures the variable is passed through to the MCP server
      # If NVIM_SOCKET_PATH is not set in the AI terminal session, it falls back to /tmp/nvim
      description = "Neovim MCP server for enhanced code understanding and assistance within Neovim.";
    };
    serena = {
      command = "nix";
      args = [
        "run"
        "github:oraios/serena"
        "--"
        "start-mcp-server"
        "--context"
        "ide-assistant"
      ];
      description = "Serena IDE assistant with AGENTS.md integration for project-aware coding assistance";
    };
  };

  additionalServersAttrset = values.llm.mcp.servers or { };
  additionalServersList = values.llm.mcp.additionalServers or [ ];

  additionalServersFromList = builtins.listToAttrs (
    map (server: {
      inherit (server) name;
      value = {
        inherit (server) type description;
        url = server.url or null;
        command = server.command or null;
        args = server.args or [ ];
        env = server.env or { };
        enabled = server.enabled or true;
      };
    }) additionalServersList
  );

  allServers = defaultServers // additionalServersAttrset // additionalServersFromList;
in
{
  servers = allServers;
}
