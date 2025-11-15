# Example LLM Configuration for values.nix
# Add this section to your existing values.nix file

{
  # ... your existing configuration ...

  llm = {
    # AGENTS.md Integration
    agentsMd = {
      enabled = true;
      autoUpdate = true;
    };

    # Execution Environment Configuration
    execution = {
      nixShell = {
        enabled = true;
        autoDeps = true;
        sandbox = true;
      };

      terminal = {
        wezterm = {
          enabled = true;
          newWindow = true;
          monitor = true;
        };
      };

      isolation = {
        enabled = true;
        monitoring = true;
        timeout = 300;
      };
    };

    # Claude Desktop Configuration
    claude = {
      enabled = true;

      mcp = {
        aws = {
          region = "us-east-1";
          enabled = true;
        };

        # Additional MCP servers for Claude
        additionalServers = {
          # Example: Custom MCP server
          # "my-custom-server" = {
          #   command = "node";
          #   args = ["./my-mcp-server.js"];
          #   description = "Custom MCP server for specific functionality";
          # };
        };
      };
    };

    # Goose AI Assistant Configuration
    goose = {
      enabled = true;
      provider = "github_copilot";
      model = "gpt-4o-mini";
      leadModel = null; # Use default
      alphaFeatures = true;
      mode = "smart_approve";
    };

    # Opencode IDE Configuration
    opencode = {
      enabled = true;
      theme = "auto"; # Uses system theme
      autoupdate = true;
      share = "disabled";
    };

    # Cursor CLI Configuration
    cursor = {
      enabled = true;

      permissions = {
        shell = {
          allowed = [
            "ls"
            "rg"
            "head"
            "git"
            "wc"
            "grep"
            "cd"
            "make"
            "pwd"
            "mkdir"
            "cat"
            "which"
            "tail"
            "find"
            "npm"
            "pnpm"
            "yarn"
            "python"
            "node"
            "go"
            "rustc"
            "cargo"
            "docker"
            "kubectl"
            "terraform"
            "nix"
          ];
        };

        kubectl = {
          allowed = [
            "get"
            "describe"
            "logs"
            "explain"
            "api-resources"
            "api-versions"
            "cluster-info"
            "version"
            "config"
            "top"
            "apply"
            "delete"
            "create"
            "edit"
          ];
        };
      };

      vimMode = true;
    };

    # MCP Servers Configuration
    mcp = {
      # Additional MCP servers (attrset format)
      servers = {
        # Example: Custom development server
        # "dev-tools" = {
        #   command = "uvx";
        #   args = ["my-dev-mcp-server"];
        #   description = "Development tools MCP server";
        #   env = {
        #     DEV_MODE = "true";
        #   };
        # };
      };

      # Additional MCP servers (list format)
      additionalServers = [
        # Example: HTTP-based MCP server
        # {
        #   name = "my-http-server";
        #   type = "http";
        #   url = "http://localhost:8080/mcp";
        #   description = "HTTP-based MCP server";
        #   enabled = true;
        # }
      ];
    };
  };

  # ... rest of your configuration ...
}
