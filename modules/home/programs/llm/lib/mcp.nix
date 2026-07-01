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

  # Format MCP servers for Goose. Field-name footgun: goose uses `uri` (not
  # `url`) and `type = "streamable_http"` for modern MCP per the 2025-03-26
  # spec; `sse` is legacy and only used when a server advertises only `/sse`.
  formatForGoose =
    let
      capitalizeFirst =
        str:
        let
          firstChar = builtins.substring 0 1 str;
          rest = builtins.substring 1 (-1) str;
        in
        (toUpper firstChar) + rest;
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

  # Format MCP servers for Copilot CLI. Copilot requires explicit `type` and
  # an explicit `tools` allowlist for http servers (omitting it suppresses
  # tool exposure); `["*"]` opts in to all tools.
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
          type = "stdio";
          inherit (server) command;
          inherit (server) args;
        }
    ) servers;

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
