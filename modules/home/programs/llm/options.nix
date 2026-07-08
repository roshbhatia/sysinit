{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.llm = {
    claudeCode = {
      marketplaces = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Claude Code marketplaces, keyed by the marketplace name used in
          the CLI (e.g. `Laurel` in `/plugin install <plugin>@Laurel`).

          Values are filesystem paths to marketplace directories:
          - Absolute paths (starting with `/`) pass through verbatim.
          - Relative paths are resolved against `home.homeDirectory`.

          Paths are forwarded as strings — never Nix path literals — so the
          referenced directory is not copied into the Nix store. Use this
          to declare marketplaces backed by private clones without leaking
          remote refs into the public configuration.

          The home-manager module writes a directory-source entry, so
          pulling updates from the upstream remote is the operator's
          responsibility (e.g. periodic `git pull` in the clone). The CLI
          will not auto-refresh a directory-source marketplace.
        '';
        example = lib.literalExpression ''
          {
            Laurel = "code/work/ai-tooling";
          }
        '';
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Claude Code plugin directories, passed to the CLI as
          `--plugin-dir <path>`. Each entry uses the same
          absolute/relative resolution rules as `marketplaces`.
        '';
        example = lib.literalExpression ''
          [ "code/work/ai-tooling/Laurel" ]
        '';
      };

      enabledPlugins = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Claude Code marketplace plugins to enable persistently, written
          to `enabledPlugins` in the user `settings.json` so they load in
          every repository with no per-invocation flags.

          Each entry is a `<plugin>@<marketplace>` key, where the
          marketplace name matches a key declared in `marketplaces`
          (e.g. `laurel-eng@Laurel`).

          This is distinct from `plugins`: it does NOT use `--plugin-dir`
          (the local-dev override hatch). Use this for marketplace-backed
          plugins that should be globally enabled; use `plugins` only to
          point the CLI at an unpackaged local plugin directory.

          When empty, no `enabledPlugins` key is written, leaving
          `settings.json` identical to its prior form.
        '';
        example = lib.literalExpression ''
          [ "laurel-eng@Laurel" ]
        '';
      };
    };

    mcp = {
      additionalServers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              type = mkOption {
                type = types.enum [
                  "local"
                  "http"
                ];
                default = "local";
                description = "Transport type — stdio (`local`) or remote `http`.";
              };
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Command to run the MCP server (stdio servers only).";
              };
              args = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Arguments to pass to the MCP server command";
              };
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Remote endpoint URL (http servers only).";
              };
              headers = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Headers to send with each request (http servers only).";
              };
              description = mkOption {
                type = types.str;
                default = "";
                description = "Description of the MCP server";
              };
            };
          }
        );
        default = { };
        description = "Additional Model Context Protocol servers";
      };
    };
  };
}
