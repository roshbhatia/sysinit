{
  defaultModel = {
    provider = "anthropic";
    name = "claude-3-5-sonnet";
    temperature = 0.7;
    max_tokens = 8192;
  };

  defaultTimeout = 300;

  permissions = {
    conservative = {
      file_operations = "prompt";
      network_access = "allow";
      shell_commands = "prompt";
    };

    sandbox = {
      enabled = true;
      allow_network = true;
      allow_file_write = true;
    };
  };

  ui = {
    theme = "system";
    auto_format = true;
    syntax_highlighting = true;
  };

  formatLspForOpencode =
    lspConfig:
    builtins.mapAttrs (_name: lsp: {
      command = (lsp.command or [ ]) ++ (lsp.args or [ ]);
      extensions = lsp.extensions or [ ];
    }) lspConfig;

  formatLspForCrush =
    lspConfig:
    builtins.mapAttrs (_name: lsp: {
      command =
        if builtins.length lsp.command == 1 then
          builtins.elemAt lsp.command 0
        else
          builtins.elemAt lsp.command 0;
      args = lsp.args or null;
      env = lsp.env or null;
    }) lspConfig;

  formatMcpForOpencode =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          enabled = server.enabled or true;
          url = server.url;
          description = server.description or "";
        }
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
          description = server.description or "";
        }
    ) mcpServers;

  formatMcpForGoose =
    lib: mcpServers:
    lib.mapAttrs (name: server: {
      args = server.args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (lib.stringLength name) name;
      timeout = 300;
      type = "stdio";
    }) mcpServers;

  formatMcpForClaude =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          url = server.url;
          description = server.description or "";
          enabled = server.enabled or true;
        }
      else
        {
          command = server.command;
          args = server.args;
          description = server.description or "";
          enabled = server.enabled or true;
          env = server.env or { };
        }
    ) mcpServers;

  gooseBuiltinExtensions = {
    autovisualiser = {
      available_tools = [ ];
      bundled = true;
      description = null;
      display_name = "Auto Visualiser";
      enabled = true;
      name = "autovisualiser";
      timeout = 300;
      type = "builtin";
    };
    computercontroller = {
      bundled = true;
      display_name = "Computer Controller";
      enabled = true;
      name = "computercontroller";
      timeout = 300;
      type = "builtin";
    };
    developer = {
      bundled = true;
      display_name = "Developer";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
    };
  };
}
