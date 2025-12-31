{
  lib,
  values,
  ...
}:
let
  mcp = import ../shared/mcp.nix { inherit lib values; };
  directives = import ../shared/directives.nix;

  gooseBuiltinExtensions = {
    autovisualiser = {
      available_tools = [ ];
      bundled = true;
      description = null;
      display_name = "Auto Visualiser";
      enabled = true;
      name = "autovisualiser";
      timeout = 300;
      type = "builtin";
    };
    computercontroller = {
      available_tools = [
        "browser_action"
        "computer_use"
      ];
      bundled = true;
      display_name = "Computer Controller";
      enabled = true;
      name = "computercontroller";
      timeout = 300;
      type = "builtin";
    };
    developer = {
      available_tools = [
        "text_editor"
        "shell"
        "analyze"
        "screen_capture"
        "image_processor"
      ];
      bundled = true;
      display_name = "Developer";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
    };
  };

  gooseHintsMd = ''
    ${directives.general}
  '';

  capitalizeFirst =
    str:
    let
      firstChar = builtins.substring 0 1 str;
      rest = builtins.substring 1 (-1) str;
    in
    (builtins.strings.toUpper firstChar) + rest;

  formatMcpForGoose =
    mcp:
    builtins.mapAttrs (_name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name =
        capitalizeFirst (builtins.substring 0 1 _name)
        + builtins.substring 1 (builtins.stringLength _name) _name;
      timeout = 300;
      type = "stdio";
    }) mcp;

  formatPermissionsForGoose = _perms: {
    shell = {
      allow = map (cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd) mcp.allPermissions;
      deny = [ ];
    };
  };

  gooseConfig = builtins.toJSON {
    ALPHA_FEATURES = true;
    EDIT_MODE = "vi";
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";
    extensions = gooseBuiltinExtensions // formatMcpForGoose mcp.servers;
    shell = formatPermissionsForGoose mcp.allPermissions;
  };

in
{
  xdg.configFile = {
    "goose/config.yaml".text = gooseConfig;
    "goose/goosehints.md".text = gooseHintsMd;
  };
}
