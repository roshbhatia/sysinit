{ lib }:

{
  # Shared MCP server formatters for different LLM applications
  formatMcpFor =
    app: mcpServers:
    let
      formatters = {
        claude =
          server:
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
            };

        opencode =
          server:
          if (server.type or "local") == "http" then
            {
              type = "remote";
              enabled = server.enabled or true;
              inherit (server) url;
            }
            // lib.attrsets.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
            // lib.attrsets.optionalAttrs (server.timeout or null != null) { inherit (server) timeout; }
          else
            {
              type = "local";
              enabled = server.enabled or true;
              command = [ server.command ] ++ server.args;
            }
            // lib.attrsets.optionalAttrs (server.env or { } != { }) { environment = server.env; };

        goose =
          server:
          if (server.type or "local") == "http" then
            {
              type = "remote";
              enabled = server.enabled or true;
              inherit (server) url;
            }
            // lib.attrsets.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
          else
            {
              type = "local";
              enabled = server.enabled or true;
              command = [ server.command ] ++ server.args;
              env = server.env or { };
            };

        copilot =
          server:
          if (server.type or "local") == "http" then
            {
              type = "http";
              enabled = server.enabled or true;
              inherit (server) url;
            }
          else
            {
              type = "local";
              enabled = server.enabled or true;
              inherit (server) command args;
              env = server.env or { };
            };

        crush =
          server:
          if (server.type or "local") == "http" then
            {
              type = "remote";
              enabled = server.enabled or true;
              inherit (server) url;
            }
          else
            {
              type = "local";
              enabled = server.enabled or true;
              command = [ server.command ] ++ server.args;
              env = server.env or { };
            };

        amp =
          server:
          if (server.type or "local") == "http" then
            {
              type = "remote";
              enabled = server.enabled or true;
              inherit (server) url;
            }
            // lib.attrsets.optionalAttrs (server.headers or null != null) { inherit (server) headers; }
          else
            {
              type = "local";
              enabled = server.enabled or true;
              command = [ server.command ] ++ server.args;
              env = server.env or { };
            };
      };
    in
    builtins.mapAttrs (_: formatters.${app}) mcpServers;
}
