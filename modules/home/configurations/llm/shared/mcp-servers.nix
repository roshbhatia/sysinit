{
  values ? { },
  lib,
}:
let
  defaultServers = {
    fetch = {
      command = "uvx";
      args = [ "mcp-server-fetch" ];
      description = "Web content fetching and processing capabilities";
    };
    git = {
      command = "uvx";
      args = [ "mcp-server-git" ];
      description = "Git version control system integration";
    };
    context7 = {
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp@latest"
      ];
      description = "Context7 MCP server for enhanced context management with AGENTS.md support";
    };
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
    "awslabs.aws-api-mcp-server" = {
      command = "uvx";
      args = [ "awslabs.aws-api-mcp-server@latest" ];
      env = {
        AWS_REGION = "us-east-1";
      };
    };
    "awslabs.terraform-mcp-server" = {
      command = "uvx";
      args = [ "awslabs.terraform-mcp-server@latest" ];
      env = {
        FASTMCP_LOG_LEVEL = "ERROR";
      };
    };
    "awslabs.eks-mcp-server" = {
      command = "uvx";
      args = [
        "awslabs.eks-mcp-server@latest"
        "--allow-write"
        "--allow-sensitive-data-access"
      ];
      env = {
        AWS_REGION = "us-east-1";
      };
    };
    "awslabs.cloudtrail-mcp-server" = {
      command = "uvx";
      args = [ "awslabs.cloudtrail-mcp-server@latest" ];
      env = {
        FASTMCP_LOG_LEVEL = "ERROR";
      };
    };
  };

  # Additional servers from values file (attrset format)
  additionalServersAttrset = values.llm.mcp.servers or { };

  # Additional servers from values file (list format)
  # Format: [{ name = "server-name"; url = "..."; type = "http"; description = "..."; }]
  additionalServersList = values.llm.mcp.additionalServers or [ ];

  # Convert list format to attrset
  additionalServersFromList = lib.builtins.listToAttrs (
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
