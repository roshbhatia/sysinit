{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Coding-focused toolset surface. Deliberately narrower than `hermes-acp`
  # (which adds browser, vision, code_execution) or `hermes-cli` (which adds
  # clarify, messaging, TTS, cronjob). Matches the tool surface of
  # claude-code so behavior stays predictable across harnesses. The "cli"
  # platform key drives both `hermes chat` (REPL) and `hermes --tui` since
  # the TUI runs through cmd_chat with platform=cli.
  codingToolsets = [
    "terminal"
    "file"
    "skills"
    "todo"
    "memory"
    "delegation"
    "web"
  ];

  codingSystemPrompt = kit.mkInstructions "~/.claude/skills";

  # Nix-managed base. `model.*`, `custom_providers`, `tools_config`,
  # `provider_routing`, and `onboarding.seen` are intentionally absent —
  # hermes mutates those at runtime (via `hermes model`, `hermes setup`,
  # `hermes tools`) and the activation script below preserves them.
  hermesBase = {
    platform_toolsets = {
      cli = codingToolsets;
    };

    agent = {
      max_turns = 90;
      verbose = false;
      system_prompt = codingSystemPrompt;
    };

    compression = {
      enabled = true;
      threshold = 0.50;
    };

    display = {
      compact = false;
      streaming = true;
      show_reasoning = false;
      persistent_output = true;
    };

    delegation = {
      max_iterations = 45;
    };

    # `hermes --tui` auto-resumes the most recent session by default. Off
    # so cold starts always begin from a clean slate.
    tui_auto_resume_recent = false;

    mcp_servers = llmLib.mcp.formatForHermes kit.mcpServers.servers;
  };

  hermesConfigBase = pkgs.writeText "hermes-config-base.yaml" (builtins.toJSON hermesBase);

  # Mirrors the deep-merge pattern from goose.nix. The existing user
  # config goes on the LEFT and our nix-managed base on the RIGHT, so the
  # nix values win on overlap. Keys we don't set (model.*, custom_providers,
  # tools_config, etc.) flow through untouched from the user file, so the
  # `hermes model` / `hermes tools` mutations survive reactivation.
  updateHermesConfig = pkgs.writeShellScript "update-hermes-config" ''
    set -euo pipefail

    target="$HOME/.hermes/config.yaml"
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    if [ -L "$target" ]; then
      rm -f "$target"
    fi

    merged="$(mktemp "''${target}.tmp.XXXXXX")"
    trap 'rm -f "$merged"' EXIT

    if [ -f "$target" ]; then
      ${pkgs.yq-go}/bin/yq eval-all \
        '. as $item ireduce ({}; . * $item)' \
        "$target" ${hermesConfigBase} > "$merged"
    else
      cp ${hermesConfigBase} "$merged"
    fi

    mv "$merged" "$target"
    chmod u+w "$target"
  '';
in
{
  home.packages = [ pkgs.hermes-agent ];

  # `hermes chat` checks HERMES_TUI=1 and routes to the Ink/React TUI.
  # Other subcommands (oneshot, cron, dashboard, mcp, ...) ignore this and
  # run their normal flow, so setting it globally is safe.
  home.sessionVariables = {
    HERMES_TUI = "1";
  };

  home.activation.hermesConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateHermesConfig}
  '';
}
