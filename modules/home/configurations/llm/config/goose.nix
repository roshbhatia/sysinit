{
  lib,
  values,
  ...
}:
let
  llmLib = import ../../../../shared/lib/llm { inherit lib; };
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
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

  gooseConfig = builtins.toJSON {
    ALPHA_FEATURES = true;
    EDIT_MODE = "vi";
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";
    extensions = gooseBuiltinExtensions // (llmLib.formatMcpForGoose mcpServers.servers);
    shell = llmLib.formatPermissionsForGoose llmLib.permissions;
  };
in
{
  xdg.configFile = {
    "goose/config.yaml".text = gooseConfig;
    "goose/goosehints.md".text = gooseHintsMd;
  };
}
