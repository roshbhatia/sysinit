{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  notify = import ./notify.nix { inherit pkgs lib; };

  defaultInstructions = kit.mkInstructions "~/.claude/skills";

  statuslineScript = pkgs.writeShellScript "claude-statusline" (builtins.readFile ./statusline.sh);

  # SessionEnd hook: appends a dumb pointer line per session to the cross-session
  # worklog. Summaries are filled in later by the `worklog` skill, not here.
  worklogScript = pkgs.writeShellScript "claude-worklog" (builtins.readFile ./worklog.sh);

  subagents = lib.filterAttrs (
    n: _: n != "formatSubagentAsMarkdown"
  ) kit.llmLib.instructions.subagents;

  ccCfg = config.sysinit.llm.claudeCode;
  # Resolve relative paths against $HOME so the upstream module always
  # receives an absolute string (its `path` type rejects relatives).
  resolvePath = p: if lib.hasPrefix "/" p then p else "${config.home.homeDirectory}/${p}";
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    marketplaces = lib.mapAttrs (_: resolvePath) ccCfg.marketplaces;
    plugins = map resolvePath ccCfg.plugins;

    settings = {
      # The company `laurel-eng` tooling installs an enterprise
      # managed-settings.json (model + OTEL telemetry) that sits ABOVE this
      # user settings.json in precedence. Deliberately leave `model` and the
      # OTEL `env` keys unset here so the two layers never silently fight.
      permissions = {
        allow = llmLib.allowlist.formatForClaude llmLib.allowlist.tierA;
        # Reversible local writes (formatters, `git add`, `nix build`): force a
        # confirmation prompt rather than auto-allowing or hard-denying.
        ask = llmLib.allowlist.formatForClaude llmLib.allowlist.tierB;
      };

      editorMode = "vim";

      # Use our explicit Co-Authored-By trailer (per global CLAUDE.md) instead
      # of the built-in one, so commits don't carry two attribution lines.
      includeCoAuthoredBy = false;

      statusLine = {
        type = "command";
        command = "${statuslineScript}";
      };

      # Not in the public settings reference as of 2.1.x; kept as known-good
      # internal keys — verify via /config after major upgrades.
      tui = "fullscreen";
      autoCompactWindow = 145000;
      autoDreamEnabled = true;

      hooks = {
        SessionEnd = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${worklogScript}";
                async = true;
              }
            ];
          }
        ];
        # Permission prompts and idle waits: agent-notify reads the event JSON on
        # stdin and refines the generic "attention" into approval/idle from the
        # notification message itself.
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${notify.exe} claude attention";
                async = true;
              }
            ];
          }
        ];
        # Turn finished — your move.
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${notify.exe} claude done";
                async = true;
              }
            ];
          }
        ];
      };
    };

    context = defaultInstructions;

    agents = lib.mapAttrs (
      name: agentConfig:
      kit.llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
      }
    ) subagents;
  };
}
