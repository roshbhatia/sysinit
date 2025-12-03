{
  ...
}:
let
  common = import ../shared/common.nix;

  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = common.formatPermissionsForCursor common.commonShellPermissions;
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
  xdg.configFile."cursor/cli-config.json" = {
    text = cursorConfig;
    force = true;
  };
  home.file.".cursor/cli-config.json" = {
    text = cursorConfig;
    force = true;
  };
}
