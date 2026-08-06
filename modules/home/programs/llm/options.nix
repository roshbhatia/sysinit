{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.llm = {
    managedFiles = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Per-file kill switch. When false the target is neither read nor
                written, so one misbehaving harness is disabled without
                reverting the others.
              '';
            };
            path = mkOption {
              type = types.str;
              description = "Target path, relative to the home directory.";
            };
            content = mkOption {
              type = types.attrs;
              default = { };
              description = ''
                The content Nix declares. Written as JSON and converted to
                `format` on the way out, so one merge path serves every format.
              '';
            };
            contentFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                An already-rendered file to use instead of `content`, in
                `format`. For a target whose content another Home Manager
                module assembles, so this module does not duplicate an
                assembly that would drift on the next upgrade.
              '';
            };
            createIfMissing = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to create the target when it does not exist. Set false
                for a file that is the harness's own state and should not be
                conjured on a machine where the harness has never run.
              '';
            };
            enforce = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Top-level blocks this repository owns outright, reasserted on
                every activation rather than merged. A list is compared whole,
                so without this a harness that appends one entry makes the next
                Nix edit to that list an unresolvable conflict. A key the
                harness drops is also restored, which for an enforcement
                setting is required rather than a preference.
              '';
            };
            format = mkOption {
              type = types.enum [
                "json"
                "yaml"
                "toml"
              ];
              default = "json";
              description = "On-disk format of the target file.";
            };
            schema = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Optional path to a JSON Schema. The merged result is validated
                against it before it replaces the target.
              '';
            };
            retire = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Top-level keys deleted from the target on EVERY activation. These
                are keys this repository used to declare, or that the harness
                writes and nothing reads, and which must not persist.

                It applies on every activation, not only on adoption, because a
                key that was never declared is absent from the recorded base, and
                the three-way merge preserves a base-absent key by design. Without
                this, such a key is immortal: the harness rewrites it and no code
                path removes it. A target whose schema sets
                `additionalProperties: false` then fails validation as well.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Harness config files that both Nix and the harness write. Each is
        installed as a real writable file and reconciled at activation by a
        three-way merge against a recorded base. Declaring a path here and in
        `home.file` or `xdg.configFile` is an error.
      '';
    };

    instructions.extraSections = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            title = mkOption {
              type = types.str;
              description = ''
                Section heading, rendered as `## <title>`. Must not collide
                with a section this repository owns.
              '';
            };
            body = mkOption {
              type = types.lines;
              description = ''
                Section text. `{{agent}}` and its variants are rendered per
                harness, the same as the built-in sections.
              '';
            };
          };
        }
      );
      default = [ ];
      description = ''
        Cross-repo rules a downstream flake adds to every harness's global
        context file, rendered after the built-in sections.

        For a rule that holds in every repository on one machine and that no
        single repository can state: a work machine's confidentiality boundary,
        for instance. A fact about one repository belongs in that repository's
        `AGENTS.md`, and a domain rule belongs in the skill that owns it. The
        line budget is separate from and much smaller than the built-in one, so
        a downstream flake cannot crowd out the shared rules.
      '';
    };

    mcp = {
      slackAllowedSendChannels = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Slack channel or DM IDs to which the Slack send tools
          (slack_send_message, slack_send_message_draft) are allowed
          without approval. slack_schedule_message is always blocked.
          Set to the channel_ids used by approved skills; all other
          destinations remain blocked by the PreToolUse guard.
        '';
      };

      disabledBuiltinServers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          claude.ai built-in MCP server names to disable globally.
          Suppresses the "N servers need authentication" startup warning
          for integrations the user never uses.
          Names must match exactly (e.g. "claude.ai Airtable").
        '';
      };

      suppressedServers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Server names to drop from the rendered MCP config on this host, after
          `additionalServers` is merged.

          For a host that reaches a server through an aggregating gateway instead of
          directly. Registering both shows every tool twice, and the direct entry is
          the one that has to go, because the gateway cannot un-register itself.
          Names must match a key in `additionalServers`.
        '';
      };

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
              env = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Environment variables for local stdio servers.";
              };
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Whether the server should be enabled in harnesses that support per-server toggles.";
              };
              timeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Optional server timeout in seconds for harnesses that support it.";
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
