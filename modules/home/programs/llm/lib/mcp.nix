{ lib }:
with lib;
{
  # Format MCP servers for Claude Desktop
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

  # Format MCP servers for OpenCode
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
            // optionalAttrs (server.headers or null != null) { inherit (server) headers; }
            // optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
          else
            {
              type = "local";
              command = [ server.command ] ++ server.args;
            }
            // optionalAttrs (server.env or { } != { }) { environment = server.env; };
      in
      baseConfig // { enabled = if isDisabled then false else (server.enabled or true); }
    ) servers;

  # Format MCP servers for Codex CLI (TOML format)
  formatForCodex =
    servers:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: server:
        if (server.type or "local") == "http" then
          ''
            [mcp_servers."${name}"]
            url = "${server.url}"
            ${optionalString (server.description or "" != "") ''description = "${server.description}"''}
          ''
        else
          ''
            [mcp_servers."${name}"]
            command = "${server.command}"
            ${optionalString ((server.args or [ ]) != [ ])
              "args = [${concatMapStringsSep ", " (arg: ''"${arg}"'') server.args}]"
            }
            ${optionalString (server.env or { } != { }) ''
              [mcp_servers."${name}".env]
              ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k} = \"${v}\"") server.env)}
            ''}
            ${optionalString (server.description or "" != "") ''description = "${server.description}"''}
          ''
      ) servers
    );

  # Format MCP servers for Gemini CLI (TOML format)
  formatForGemini =
    servers:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: server:
        if (server.type or "local") == "http" then
          ''
            [mcpServers."${name}"]
            type = "http"
            url = "${server.url}"
            description = "${server.description or ""}"
          ''
        else
          ''
            [mcpServers."${name}"]
            command = "${server.command}"
            args = [${concatMapStringsSep ", " (arg: ''"${arg}"'') (server.args or [ ])}]
            description = "${server.description or ""}"
            ${optionalString (server.env or { } != { }) "env = ${builtins.toJSON server.env}"}
          ''
      ) servers
    );

  # Format MCP servers for Amp
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

  # Format MCP servers for Goose
  formatForGoose =
    let
      capitalizeFirst =
        str:
        let
          firstChar = builtins.substring 0 1 str;
          rest = builtins.substring 1 (-1) str;
        in
        (toUpper firstChar) + rest;
    in
    mcp:
    builtins.mapAttrs (_name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name =
        capitalizeFirst (builtins.substring 0 1 _name)
        + builtins.substring 1 (builtins.stringLength _name) _name;
      timeout = 300;
      type = "stdio";
    }) mcp;

  # Format MCP servers for Copilot CLI
  formatForCopilot =
    servers:
    builtins.mapAttrs (_name: server: {
      type = "stdio";
      inherit (server) command;
      inherit (server) args;
    }) servers;

  # Format permissions for Cursor
  formatPermissionsForCursor = allPermissions: map (cmd: "Shell(${cmd})") allPermissions;

  # Format permissions for Goose shell
  formatPermissionsForGoose = allPermissions: {
    shell = {
      allow = map (cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd) allPermissions;
      deny = [ ];
    };
  };
}
