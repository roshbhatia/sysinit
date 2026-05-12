{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  gooseConfig = builtins.toJSON {
    EDIT_MODE = "vi";
    GOOSE_CLI_MIN_PRIORITY = 0.2;
    GOOSE_CLI_THEME = "ansi";
    GOOSE_MODE = "smart_approve";
    GOOSE_TOOLSHIM = true;

    extensions = llmLib.mcp.formatForGoose kit.mcpServers.servers;
    # goose's existing shell allowlist is sourced from mcp.nix's categorized
    # permissions (git/github/docker/k8s/nix/utilities/crossplane). Migrating
    # to the canonical Tier A would change the semantic surface; deferred to
    # a future revisit. The kit migration above unifies imports only.
    shell = llmLib.mcp.formatPermissionsForGoose kit.mcpServers.allPermissions;
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

  home.packages = [ pkgs.goose-cli ];
}
