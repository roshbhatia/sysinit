{ lib, ... }:

let
  inherit (lib) mkOption types;
  packagedHarnesses = builtins.attrNames (
    lib.filterAttrs (_: harness: harness.package != null) (import ./harnesses/registry.nix)
  );
in
{
  options.sysinit.llm = {
    enabledOptInSkills = mkOption {
      type = types.listOf (types.enum (import ./skills/catalog.nix).optIn);
      default = [ ];
      description = "Specialist skills to publish in the managed skill roots.";
    };
    agentFavorites = mkOption {
      type = types.listOf (types.enum (builtins.attrNames (import ./harnesses/registry.nix)));
      default = [
        "codex"
        "opencode"
        "claude"
      ];
      description = "Agent launcher favorites in display order, independent of installed CLI packages.";
    };

    workspace.enable = lib.mkEnableOption "agent workspace session, observer, and feedback integration";

    harnessPackages = mkOption {
      type = types.listOf (types.enum packagedHarnesses);
      default = packagedHarnesses;
      description = "Registry harnesses whose CLI packages the development profile installs directly.";
    };

    optionalSubagents = mkOption {
      type = types.listOf (
        types.enum [
          "implementor"
          "librarian"
          "oracle"
        ]
      );
      default = [ ];
      description = "Additional specialized agents to expose in Claude Code and OpenCode.";
    };
    notifications = {
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Composable agent-notify/v1 policy overrides, validated against the agent-signals JSON schema during the build.";
      };
      icons = mkOption {
        type = types.attrsOf types.path;
        default = { };
        description = "SVG overrides keyed by harness ID; agent overrides the generic fallback.";
      };
    };
    instructions = {
      additionalSkillDescriptions = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Descriptions of downstream-owned skills for manual discovery; shared sysinit does not name host-specific workflows.";
      };

      skillRoutes = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              intent = mkOption { type = types.str; };
              skills = mkOption { type = types.listOf types.str; };
            };
          }
        );
        default = [ ];
        description = "Compact workflow selection hints; downstream modules append their own domain routes.";
      };

      extraSections = mkOption {
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

    };

    amp.remoteExecution = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this host uses Amp's remote execution: orbs, and threads that
        ampcode.com opens on this machine.

        Off by default. Amp bills an orb against the Amp subscription, so on a
        host whose active model provider is a linked ChatGPT subscription an orb
        routes the work around the provider the host is meant to use. It also
        puts the working tree on a sandbox this repository does not control,
        which the work machine's confidentiality boundary does not allow.

        When false, `amp.remoteThreadCreation.enabled` is false and `amp orb` is
        rejected as a Bash command. Neither stops the owner running `amp orb`
        themselves; this governs what an agent may do.
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

          This does NOT remove the connector or its tools. Verified against
          Claude Code 2.1.233: with 43 names listed here,
          `claude mcp get "claude.ai Gmail"` still reports Connected and
          Gmail's tools still reach the session. The connector fetch has only
          two kill switches, both all-or-nothing: the
          `disableClaudeAiConnectors` setting and the
          `ENABLE_CLAUDEAI_MCP_SERVERS` env var. Per-connector opt-out is an
          open request, not a shipped feature:
          anthropics/claude-code issues 26625, 45158 and 58453.
        '';
      };

      harnessAllowedTools = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
        example = {
          claude = [ "mcp__read-only-server__get_record" ];
        };
        description = ''
          Exact MCP tools a host permits a harness to call without approval.
          Keep write operations out of this list. A host-owned gateway must
          enumerate its read-only surface here instead of approving a server
          wildcard whose targets can change independently.
        '';
      };

      harnessSuppressedServers = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
        example = {
          opencode = [ "work-services" ];
        };
        description = ''
          Server names to omit from one harness after the host server catalog
          is assembled. This keeps constrained harnesses from inheriting
          servers that cannot fit their context or authentication model.
        '';
      };

      harnessOverrides = mkOption {
        type = types.attrsOf (types.attrsOf types.attrs);
        default = { };
        example = {
          opencode.agentgateway.url = "http://127.0.0.1:18081/mcp";
        };
        description = ''
          Per-harness replacements for a server's definition, keyed by harness
          name then server name, applied after `suppressedServers`.

          For a harness that must reach the same server on different terms than
          the rest of the host. A local model cannot afford the full tool
          surface an aggregating gateway exposes, so it points at a filtered
          endpoint while every other harness keeps the unfiltered one. The
          server name must already exist for this host, because this replaces a
          definition rather than adding one.
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
                  "sse"
                ];
                default = "local";
                description = "Upstream transport: stdio (`local`), Streamable HTTP (`http`), or legacy SSE (`sse`).";
              };
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Command to run the MCP server (stdio servers only).";
              };
              gateway = mkOption {
                type = types.bool;
                default = false;
                description = "Whether this HTTP endpoint is already a host-owned loopback agentgateway.";
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
