{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";
  commandPath = llmLib.commandPath.render profileBin;

  bashGuardScript = llmLib.guards.mkBashGuard {
    inherit pkgs;
    name = "codex-bash-guard";
  };

  # codex sends to the endpoint verbatim and appends no signal path, unlike
  # every other OTLP client here. A bare 4318 makes it POST to `/`, which the
  # collector answers with 404, so nothing codex emitted ever reached traces.
  otlpHttp = signal: {
    endpoint = "http://127.0.0.1:4318/v1/${signal}";
    protocol = "json";
  };

  compactPrompt = ''
    Compact this Codex session for continuation. Preserve only context needed to keep working correctly.

    Keep:
    - The newest user request and any later corrections or overrides.
    - Current cwd, repo, branch, git status summary, active OpenSpec change names, and task status.
    - Files changed, decisions made, validation commands and results, blockers, running sessions, ports, and PIDs.
    - Harness-specific findings: hook event names, config paths, MCP shape differences, and docs already verified.
    - Any user-owned dirty files that must not be reverted.

    Drop:
    - Verbose command output after the relevant result has been captured.
    - Superseded exploration, duplicate file reads, and stale plans.
    - Source excerpts that are no longer needed for the next action.

    End with the exact next action to take.
  '';

  codexProfiles = {
    default.reasoning_effort = "low";
    spec = {
      reasoning_effort = "high";
      model_reasoning_summary = "detailed";
    };
  };

  codexManagedFiles = [ "config.toml" ] ++ map (n: "${n}.config.toml") (lib.attrNames codexProfiles);

  retireLegacyHooks = pkgs.writeShellScript "codex-retire-legacy-hooks" ''
    set -euo pipefail
    legacy_hooks="$HOME/.codex/hooks.json"
    if [ -e "$legacy_hooks" ] || [ -L "$legacy_hooks" ]; then
      backup="$HOME/.codex/hooks.json.disabled"
      if [ -e "$backup" ] || [ -L "$backup" ]; then
        n=1
        while [ -e "$backup.$n" ] || [ -L "$backup.$n" ]; do
          n=$((n + 1))
        done
        backup="$backup.$n"
      fi
      mv "$legacy_hooks" "$backup"
    fi
  '';
in
{
  home = {
    packages = [ bashGuardScript ];
    activation.codexRetireLegacyHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${retireLegacyHooks}
    '';
    file = lib.genAttrs (map (f: ".codex/${f}") codexManagedFiles) (_: {
      enable = lib.mkForce false;
    });
  };

  assertions = [
    {
      assertion = !config.home.preferXdgDirectories;
      message = "llm/codex: home.preferXdgDirectories moves programs.codex to .config/codex, but sysinit.llm.managedFiles still points at .codex. Update the paths in harnesses/codex.nix together with the flag.";
    }
  ];

  sysinit.llm.managedFiles = lib.listToAttrs (
    map (
      f:
      lib.nameValuePair "codex-${f}" {
        path = ".codex/${f}";
        format = "toml";
        contentFile = config.home.file.".codex/${f}".source;
        enforce = lib.optionals (f == "config.toml") [
          "approval_policy"
          "sandbox_mode"
        ];
      }
    ) codexManagedFiles
  );

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    context = kit.mkInstructionsWithStyle {
      harness = "codex";
      skillsRoot = "~/.claude/skills";
      extraSections = [
        {
          title = "Slack";
          body = ''
            Codex's MCP client does not support Slack's dynamic auth flow. If you
            need Slack context or need to send a Slack message, ask Claude Code to do
            it with `claude -p '<your Slack task>'` because Claude has Slack MCP
            access configured.
          '';
        }
      ];
    };
    plugins = [ ];

    profiles = codexProfiles;

    settings = {
      check_for_update_on_startup = false;
      compact_prompt = compactPrompt;

      approval_policy = "never";

      sandbox_mode = "danger-full-access";

      # `exporter` is a serde externally-tagged enum, so the variant name is the
      # table key. Codex keeps a separate key per signal and does not fall back
      # from one to another, so all three name the same collector.
      otel = {
        # `exporter` is the logs signal; the other two are named for theirs.
        exporter."otlp-http" = otlpHttp "logs";
        trace_exporter."otlp-http" = otlpHttp "traces";
        metrics_exporter."otlp-http" = otlpHttp "metrics";

        # A prompt attribute reads <REDACTED> without this, so a turn row
        # carries no text. The collector is loopback only.
        log_user_prompt = true;
      };

      shell_environment_policy = {
        experimental_use_profile = true;
        set.PATH = commandPath;
      };

      tools = {
        web_search = true;
      };

      features = {
        hooks = true;
        multi_agent = true;
      };

      agents = {
        max_threads = 6;
        max_depth = 1;
        explore = {
          description = "Read-only planning and exploration agent for understanding code, OpenSpec changes, options, and tradeoffs before implementation.";
          nickname_candidates = [
            "Explore"
            "Planner"
            "Plan"
          ];
        };
      };

      hooks = {
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/orc session register --hook-input --source hook --harness codex --quiet";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/codex-bash-guard";
              }
            ];
          }
        ];
        PostToolUse = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-edit-event codex --apply-patch";
              }
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state codex working submit";
              }
              {
                type = "command";
                command = "${profileBin}/agent-edit-event codex --prompt";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-notify codex done ${profileBin}/agent-focus";
              }
              {
                type = "command";
                command = "${profileBin}/agent-state codex done \"your move\"";
              }
            ];
          }
        ];
      };
    };
  };
}
