{
  lib,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix {
    inherit lib;
    additionalServers = config.sysinit.llm.mcp.additionalServers;
  };

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = llmLib.mcp.formatPermissionsForCursor mcpServers.allPermissions;
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
