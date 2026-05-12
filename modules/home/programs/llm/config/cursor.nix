{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = llmLib.mcp.formatPermissionsForCursor kit.mcpServers.allPermissions;
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
    ".cursor/cli-config.json" = {
      text = cursorConfig;
      force = true;
    };
  };
}
