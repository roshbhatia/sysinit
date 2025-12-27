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

  # Goose-specific MCP formatter
  formatMcpForGoose =
    mcpServers:
    lib.mapAttrs (name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (lib.stringLength name) name;
      timeout = 300;
      type = "stdio";
    }) mcpServers;

  # Goose-specific permission formatter
  formatPermissionsForGoose =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      toRegexPattern = cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd;
    in
    {
      shell = {
        allow = map toRegexPattern allPerms;
        deny = [ ];
      };
    };

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

      extensions = common.gooseBuiltinExtensions // (formatMcpForGoose mcpServers.servers);
    }
    // (formatPermissionsForGoose common.commonShellPermissions)
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
