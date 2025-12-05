{
  lib,
  pkgs,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  directives = import ../shared/directives.nix;
  writableConfigs = import ../shared/writable-configs.nix { inherit lib pkgs; };

  gooseHintsMd = ''
    ${directives.general}
  '';

  gooseConfig = lib.generators.toYAML { } (
    {
      ALPHA_FEATURES = true;
      EDIT_MODE = "vi";
      GOOSE_CLI_THEME = "ansi";
      GOOSE_MODE = "smart_approve";
      GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";

      extensions = common.gooseBuiltinExtensions // (common.formatMcpForGoose lib mcpServers.servers);
    }
    // (common.formatPermissionsForGoose common.commonShellPermissions)
  );

  # Create writable config files
  gooseConfigFile = writableConfigs.mkWritableConfig {
    path = "goose/config.yaml";
    text = gooseConfig;
    force = false; # Preserve user edits when source unchanged
  };

  gooseHintsFile = writableConfigs.mkWritableConfig {
    path = "goose/goosehints.md";
    text = gooseHintsMd;
    force = false; # Preserve user edits when source unchanged
  };
in
{
  home.activation = {
    gooseConfig = gooseConfigFile.activation;
    gooseHints = gooseHintsFile.activation;
  };
}
