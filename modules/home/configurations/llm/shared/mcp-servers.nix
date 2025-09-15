{
  servers = {
    fetch = {
      command = "uvx";
      args = [ "mcp-server-fetch" ];
    };
    memory = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      env = {
        MEMORY_FILE_PATH = "~/.local/state/llm-memory.json";
      };
    };
    context7 = {
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp@latest"
      ];
    };
    neovim = {
      command = "npx";
      args = [
        "-y"
        "mcp-neovim-server"
      ];
    };
  };
}
