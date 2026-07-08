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

  # Codex writes runtime state (trusted projects, hook trust, etc.) into
  # ~/.codex/config.toml, but the HM module seeds read-only nix-store symlinks.
  # Replace managed TOML symlinks with writable copies and quarantine the old
  # hooks.json layer so Codex loads hooks from one representation only.
  prepareRuntime = pkgs.writeShellScript "codex-prepare-runtime" ''
    set -euo pipefail
    codex_home="$HOME/.codex"
    mkdir -p "$codex_home"

    legacy_hooks="$codex_home/hooks.json"
    if [ -e "$legacy_hooks" ] || [ -L "$legacy_hooks" ]; then
      backup="$codex_home/hooks.json.disabled"
      if [ -e "$backup" ] || [ -L "$backup" ]; then
        n=1
        while [ -e "$backup.$n" ] || [ -L "$backup.$n" ]; do
          n=$((n + 1))
        done
        backup="$backup.$n"
      fi
      mv "$legacy_hooks" "$backup"
    fi

    for f in config.toml default.config.toml spec.config.toml; do
      target="$codex_home/$f"
      if [ -L "$target" ]; then
        src="$(readlink "$target")"
        rm -f "$target"
        cp "$src" "$target"
        chmod u+w "$target"
      fi
    done
  '';
in
{
  home.activation.codexWritableConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${prepareRuntime}
  '';

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    context = kit.mkInstructions "~/.claude/skills";
    plugins = [ ];

    # Per-profile reasoning_effort. Default is `low` for fast iteration;
    # the `spec` profile uses `high` + visible reasoning summaries for
    # openspec-heavy work.
    # Invoke with `codex --profile spec` (or `-p spec`).
    # Codex 0.134.0+ reads profiles from CODEX_HOME/<name>.config.toml, so these
    # live under `programs.codex.profiles` (not `settings.profiles`, removed).
    profiles = {
      default = {
        reasoning_effort = "low";
      };
      spec = {
        reasoning_effort = "high";
        model_reasoning_summary = "detailed";
      };
    };

    settings = {
      check_for_update_on_startup = false;
      compact_prompt = compactPrompt;

      # Full-auto: execute all tool calls without approval prompts.
      # Also disables the macOS network namespace sandbox (Codex behaviour).
      approval_policy = "full-auto";

      # Opt in to the experimental Streamable HTTP MCP client (v0.44.0+). Without
      # this, URL-based MCP entries in the TOML config are silently ignored.
      experimental_use_rmcp_client = true;

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
