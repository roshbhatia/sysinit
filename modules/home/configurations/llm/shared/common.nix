{
  formatLspForOpencode =
    lspConfig:
    builtins.mapAttrs (_name: lsp: {
      command = (lsp.command or [ ]) ++ (lsp.args or [ ]);
      extensions = lsp.extensions or [ ];
    }) lspConfig;

  formatMcpForOpencode =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "remote";
          enabled = server.enabled or true;
          inherit (server) url;
        }
        // (if (server.headers or null) != null then { inherit (server) headers; } else { })
        // (if (server.timeout or null) != null then { inherit (server) timeout; } else { })
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
        }
        // (if (server.env or { }) != { } then { environment = server.env; } else { })
    ) mcpServers;

  formatMcpForGoose =
    lib: mcpServers:
    lib.mapAttrs (name: server: {
      inherit (server) args;
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
          inherit (server) url;
          description = server.description or "";
          enabled = server.enabled or true;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
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
