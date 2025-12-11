{
  lib,
  config,
  values,
  utils,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  directives = import ../shared/directives.nix;

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
  gooseConfigFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "goose/config.yaml";
    text = gooseConfig;
    force = false; # Preserve user edits when source unchanged
  };

  gooseHintsFile = utils.xdg.mkWritableXdgConfig {
    inherit config;
    path = "goose/goosehints.md";
    text = gooseHintsMd;
    force = false; # Preserve user edits when source unchanged
  };
in
{
  home.activation = {
    gooseConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] gooseConfigFile.script;
    gooseHints = lib.hm.dag.entryAfter [ "linkGeneration" ] gooseHintsFile.script;
  };
}
