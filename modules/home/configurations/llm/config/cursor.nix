{
  lib,
  ...
}:
let
  llmLib = import ../../../../shared/lib/llm { inherit lib; };
  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = llmLib.formatPermissionsForCursor llmLib.permissions;
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
  xdg.configFile = {
    "cursor/cli-config.json".text = cursorConfig;
  };
}
