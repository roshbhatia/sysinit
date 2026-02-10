{ lib }:

{
  formatMcpForOpencode =
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

  formatLspForOpencode =
    disabledServers: lspServers:
    builtins.mapAttrs (
      name: lspCfg:
      let
        cmd =
          if lspCfg ? command then
            if builtins.isList lspCfg.command then lspCfg.command else [ lspCfg.command ]
          else
            [ ];
        isDisabled = builtins.elem name disabledServers;
      in
      if isDisabled then
        { disabled = true; }
      else
        {
          command = cmd ++ (lspCfg.args or [ ]);
          extensions = lspCfg.extensions or [ ];
        }
    ) lspServers;
}
