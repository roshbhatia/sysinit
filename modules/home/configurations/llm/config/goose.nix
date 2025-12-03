{ lib, values, ... }:
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
in
{
  xdg.configFile."goose/config.yaml" = {
    text = gooseConfig;
    force = true;
  };

  xdg.configFile."goose/goosehints.md" = {
    text = gooseHintsMd;
    force = true;
  };
}
