{
  values ? { },
}:
let
  # Default MCP servers
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
      description = "Context7 MCP server for enhanced context management";
    };
    astgrep = {
      command = "npx";
      args = [
        "-y"
        "@ast-grep/cli-mcp-server"
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
        AWS_PROFILE = "your-profile";
        AWS_REGION = "us-east-1";
      };
    };
    "awslabs.cloudtrail-mcp-server" = {
      command = "uvx";
      args = [ "awslabs.cloudtrail-mcp-server@latest" ];
      env = {
        AWS_PROFILE = "[The AWS Profile Name to use for AWS access]";
        FASTMCP_LOG_LEVEL = "ERROR";
      };
    };
    "awslabs.openapi-mcp-server" = {
      command = "uvx";
      args = [ "awslabs.openapi-mcp-server@latest" ];
      env = {
        API_NAME = "your-api-name";
        API_BASE_URL = "https://api.example.com";
        API_SPEC_URL = "https://api.example.com/openapi.json";
        LOG_LEVEL = "ERROR";
        ENABLE_PROMETHEUS = "false";
        ENABLE_OPERATION_PROMPTS = "true";
        UVICORN_TIMEOUT_GRACEFUL_SHUTDOWN = "5.0";
        UVICORN_GRACEFUL_SHUTDOWN = "true";
      };
    };
  };

  # Additional servers from values file (attrset format)
  additionalServersAttrset = values.llm.mcp.servers or { };

  # Additional servers from values file (list format)
  # Format: [{ name = "server-name"; url = "..."; type = "http"; description = "..."; }]
  additionalServersList = values.llm.mcp.additionalServers or [ ];

  # Convert list format to attrset
  additionalServersFromList = builtins.listToAttrs (
    map (server: {
      name = server.name;
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

  # Merge all servers (default + attrset format + list format)
  # Priority: list format > attrset format > defaults
  allServers = defaultServers // additionalServersAttrset // additionalServersFromList;
in
{
  servers = allServers;
}
