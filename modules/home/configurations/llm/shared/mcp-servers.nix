{
  servers = {
    fetch = {
      command = "uvx";
      args = [ "mcp-server-fetch" ];
      description = "Web content fetching and processing capabilities";
      enabled = true;
    };
    git = {
      command = "uvx";
      args = [ "mcp-server-git" ];
      description = "Git version control system integration";
      enabled = true;
    };
    chroma = {
      command = "uvx";
      args = [ 
        "chroma-mcp"
        "--client-type" 
        "persistent" 
        "--data-dir" 
        "~/.local/share/chroma"
      ];
      description = "Vector database for embedding storage and retrieval with Chroma";
      enabled = true;
    };
    context7 = {
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp@latest"
      ];
      description = "Context7 MCP server for enhanced context management";
      enabled = true;
    };
    neovim = {
      command = "npx";
      args = [
        "-y"
        "mcp-neovim-server"
      ];
      description = "Neovim integration for MCP";
      enabled = true;
    };
  };
}
