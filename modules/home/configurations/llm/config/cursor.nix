{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp.nix { inherit lib values; };

  formatPermissionsForCursor = _perms: map (cmd: "Shell(${cmd})") mcpServers.allPermissions;

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = formatPermissionsForCursor mcpServers.allPermissions;
      deny = [ ];
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };

in
{
  home.file = {
    ".cursor/cli-config.json".text = cursorConfig;
  };
}
