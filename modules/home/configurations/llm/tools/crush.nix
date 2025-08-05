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
      lsp = config.lsp;
      mcp = {
      };
      permissions = config.permissions;
    };
    force = true;
  };
}
