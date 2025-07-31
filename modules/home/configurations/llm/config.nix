{
  goose = {
    editMode = "vi";
    model = "gemini-2.0-flash-001";
    plannerModel = "claude-3.7-sonnet";
    provider = "github_copilot";
  };
  mcphub = {
    uri = "https://localhost:43210/mcp";
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
          MEMORY_FILE_PATH = "~/.local/share/server-memory.json";
        };
      };
      context7 = {
        command = "npx";
        args = [
          "-y"
          "@upstash/context7-mcp@latest"
        ];
      };
      argocd-mcp = {
        command = "npx";
        args = [
          "argocd-mcp@latest"
          "stdio"
        ];
      };
    };
  };
  opencode = {
    schema = "https://opencode.ai/config.json";
    theme = "system";
    autoupdate = true;
  };
  crush = {
    schema = "https://charm.land/crush.json";
  };
}

