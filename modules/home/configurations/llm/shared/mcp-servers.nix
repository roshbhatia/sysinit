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
    serena = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/oraios/serena"
        "serena"
        "start-mcp-server"
        "--enable-web-dashboard"
        "false"
      ];
      description = "Serena IDE assistant with AGENTS.md integration for project-aware coding assistance";
    };
  };

  additionalServers = values.llm.mcp.servers or { };
  allServers = defaultServers // additionalServers;
in
{
  servers = allServers;
}
