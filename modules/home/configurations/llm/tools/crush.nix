{
  ...
}:
let
  config = import ../config/crush.nix;
in
{
  xdg.configFile."crush/crush.json" = {
    text = builtins.toJSON {
      "$schema" = config.schema;
      lsp = builtins.mapAttrs (_name: lsp: {
        command =
          if builtins.length lsp.command == 1 then
            builtins.elemAt lsp.command 0
          else
            builtins.elemAt lsp.command 0;
        args = lsp.args or null;
        env = lsp.env or null;
      }) config.lsp.lsp;
      mcp = {
      };
      permissions = config.permissions;
    };
    force = true;
  };
}
