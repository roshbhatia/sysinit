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

  # Codex's PreToolUse hook contract is identical to Claude's (same
  # `tool_input.command` payload, same `permissionDecision: "deny"` output), so
  # the shared bash guard runs verbatim here. Denies force-push, --no-verify /
  # --no-gpg-sign, reset --hard, clean -f, branch -D. Fail-open: a non-Bash tool
  # or extraction miss exits 0 and the command proceeds.
  bashGuardScript = llmLib.guards.mkBashGuard {
    inherit pkgs;
    name = "codex-bash-guard";
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

  # Codex writes runtime state (trusted projects, hook trust) into these files.
  # The old approach copied the store symlink to a writable file on first
  # activation only, so Home Manager's link step clobbered the copy on every
  # later switch and the copy-back then discarded whatever Codex had recorded.
  # They are managed files now.
  #
  # `programs.codex` folds settings, profiles, and transformed MCP servers into
  # one TOML, so the reconciler consumes the file that module already renders
  # rather than duplicating an assembly that would drift on the next upgrade.
  # Derived from the profile set below, not hand-listed. `programs.codex`
  # writes one <name>.config.toml per profile, so a hand-list silently drifts
  # into "option used but not defined" the moment a profile is renamed.
  codexProfiles = {
    default.reasoning_effort = "low";
    spec = {
      reasoning_effort = "high";
      model_reasoning_summary = "detailed";
    };
  };

  codexManagedFiles = [ "config.toml" ] ++ map (n: "${n}.config.toml") (lib.attrNames codexProfiles);

  # Quarantine the old hooks.json layer so Codex loads hooks from one
  # representation only. Not a managed file: the goal is that it not exist.
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
  home.activation.codexRetireLegacyHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${retireLegacyHooks}
  '';

  # Stop Home Manager linking these; the reconciler owns them. The `source` is
  # still evaluated, which is exactly what the reconciler consumes.
  home.file = lib.genAttrs (map (f: ".codex/${f}") codexManagedFiles) (_: {
    # mkForce so that an upstream `enable = true` would be overridden rather
    # than raise a priority conflict.
    enable = lib.mkForce false;
  });

  # preferXdgDirectories moves programs.codex to .config/codex while the paths
  # below still name .codex. The mismatch links a read-only store symlink at
  # the path codex actually reads, and the managed-file collision assertion
  # cannot see it because the two paths differ.
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
        # The approval gates are this repository's, not Codex's. Codex writes
        # this file at runtime, so without enforcement a prompt it records
        # would stand and the harness would start asking again.
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
    context =
      kit.mkInstructions {
        harness = "codex";
        skillsRoot = "~/.claude/skills";
      }
      + ''

        ## Codex-specific Slack access

        Codex's MCP client does not support Slack's dynamic auth flow. If you
        need Slack context or need to send a Slack message, ask Claude Code to do
        it with `claude -p '<your Slack task>'` because Claude has Slack MCP
        access configured.
      ''
      + "\n## Output Style\n\n"
      + kit.llmLib.instructions.outputStyleRules;
    plugins = [ ];

    # Per-profile reasoning_effort. Default is `low` for fast iteration;
    # the `spec` profile uses `high` + visible reasoning summaries for
    # openspec-heavy work.
    # Invoke with `codex --profile spec` (or `-p spec`).
    # Codex 0.134.0+ reads profiles from CODEX_HOME/<name>.config.toml, so these
    # live under `programs.codex.profiles` (not `settings.profiles`, removed).
    profiles = codexProfiles;

    settings = {
      check_for_update_on_startup = false;
      compact_prompt = compactPrompt;

      # Execute tool calls without approval prompts. Codex 0.144.x renamed the
      # old `full-auto` policy to `never`.
      approval_policy = "never";

      sandbox_mode = "danger-full-access";

      # No `set.SHELL`. Forcing zsh on the agent caused problems the owner hit in
      # practice: an interactive-shell profile brings prompt setup, completion, and
      # plugin loading into a non-interactive tool call, and anything those write
      # to stdout lands in the agent's captured output. `experimental_use_profile`
      # stays on, so the shell codex picks by default still loads its profile.
      shell_environment_policy = {
        experimental_use_profile = true;
      };

      # Opt in to the experimental Streamable HTTP MCP client (v0.44.0+). Without
      # this, URL-based MCP entries in the TOML config are silently ignored.
      experimental_use_rmcp_client = true;

      # Give Codex the built-in web-search tool (parity with Claude/pi web access).
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

      # Lifecycle notifications via the shared agent-notify script. Codex hook
      # commands intentionally use the documented Codex event names; unlike
      # Claude, Codex 0.142.x does not support async hook entries.
      # Hook commands intentionally use stable Home Manager profile paths instead
      # of derivation-specific /nix/store paths so Codex's hook-trust cache
      # survives rebuilds.
      hooks = {
        # Mechanical destructive-command guard (parity with Claude). The script
        # self-filters on `.tool_input.command`, so no matcher is needed; Codex
        # does not support async hooks.
        PreToolUse = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe bashGuardScript}";
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
