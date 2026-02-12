{
  lib,
  values,
  pkgs,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };

  gooseConfig = builtins.toJSON {
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_TOOLSHIM = true;

    extensions = llmLib.mcp.formatForGoose mcpServers.servers;
    shell = llmLib.mcp.formatPermissionsForGoose mcpServers.allPermissions;
  };

in
{
  home.sessionVariables = {
    CONTEXT_FILE_NAMES = builtins.toJSON [
      "AGENTS.md"
      ".goosehints"
      ".cursorrules"
      "CLAUDE.md"
      "CONSTITUTION.md"
      "CONTRIBUTING.md"
      "COPILOT.md"
    ];
  };

  xdg.configFile = {
    "goose/config.yaml" = {
      text = gooseConfig;
      force = true;
    };
  };

  home.packages = with pkgs; [
    goose-cli
  ];
}
