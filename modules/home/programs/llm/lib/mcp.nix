{ lib }:
{
  formatForClaude = builtins.mapAttrs (
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
  );

  formatForOpencode =
    disabledServers: servers:
    builtins.mapAttrs (
      name: server:
      let
        isDisabled = builtins.elem name disabledServers;
        baseConfig =
          if (server.type or "local") == "http" then
            {
              type = "remote";
              inherit (server) url;
            }
            // lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
            // lib.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
          else
            {
              type = "local";
              command = [ server.command ] ++ server.args;
            }
            // lib.optionalAttrs (server.env or { } != { }) { environment = server.env; };
      in
      baseConfig // { enabled = if isDisabled then false else (server.enabled or true); }
    ) servers;

  formatForAmp =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          inherit (server) url;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
          env = server.env or { };
        }
    ) servers;

  formatForCursor =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          inherit (server) url;
        }
        // lib.optionalAttrs (server.headers or { } != { }) { inherit (server) headers; }
      else
        {
          inherit (server) command;
          args = server.args or [ ];
        }
        // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
    ) servers;

  formatForAntigravity =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          serverUrl = server.url;
        }
        // lib.optionalAttrs (server.headers or { } != { }) { inherit (server) headers; }
      else
        {
          inherit (server) command;
          args = server.args or [ ];
        }
        // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
    ) servers;

  formatForGoose =
    let
      capitalizeFirst =
        str:
        let
          firstChar = builtins.substring 0 1 str;
          rest = builtins.substring 1 (-1) str;
        in
        (lib.toUpper firstChar) + rest;
      gooseName = _name: capitalizeFirst (builtins.substring 0 1 _name) + builtins.substring 1 (-1) _name;
    in
    mcp:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          bundled = null;
          description = server.description or "";
          enabled = server.enabled or true;
          headers = server.headers or { };
          name = gooseName _name;
          timeout = 300;
          type = "streamable_http";
          uri = server.url;
        }
      else
        {
          inherit (server) args;
          bundled = null;
          cmd = server.command;
          description = server.description or "";
          enabled = server.enabled or true;
          env_keys = [ ];
          envs = server.env or { };
          name = gooseName _name;
          timeout = 300;
          type = "stdio";
        }
    ) mcp;

  formatForHermes =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          inherit (server) url;
        }
        // lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
        // lib.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
      else
        {
          inherit (server) command;
          inherit (server) args;
        }
        // lib.optionalAttrs (server.env or { } != { }) { inherit (server) env; }
    ) servers;

  formatForCopilot =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
          headers = server.headers or { };
          tools = [ "*" ];
        }
      else
        {
          type = "local";
          inherit (server) command;
          args = server.args or [ ];
          env = server.env or { };
          tools = [ "*" ];
        }
    ) servers;

  formatForCrush =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
        }
      else
        {
          type = "stdio";
          inherit (server) command;
          args = server.args or [ ];
        }
    ) servers;

}
