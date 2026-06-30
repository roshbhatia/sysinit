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
  # worklog (schema v2). Summaries are filled in later by the `worklog` skill,
  # not here. The hook is a PEP-723 Python script run via uv — pinned to the Nix
  # python3 with downloads forbidden, so it stays offline and reproducible (it has
  # no third-party deps; uv is just the runner the user standardizes on).
  worklogScript = pkgs.writeShellApplication {
    name = "claude-worklog";
    runtimeInputs = [
      pkgs.uv
      pkgs.python3
      pkgs.git
    ];
    text = ''
      export UV_PYTHON=${pkgs.python3}/bin/python3
      export UV_PYTHON_DOWNLOADS=never
      exec uv run --script ${./worklog.py}
    '';
  };

  # PreToolUse(Bash) guard: the mechanical floor under the global CLAUDE.md
  # prohibitions (no force-push, no --no-verify/--no-gpg-sign, no reset --hard,
  # no clean -f, no branch -D). `auto` permission mode is deliberately NOT used —
  # its built-in block list also blocks push-to-main, which this repo permits.
  # Best-effort / fail-open: bashOptions cleared so a non-zero grep never becomes
  # a hook abort (Claude treats exit 2 as a block).
  bashGuardScript = pkgs.writeShellApplication {
    name = "claude-bash-guard";
    runtimeInputs = [ pkgs.jq ];
    bashOptions = [ ];
    text = builtins.readFile ./claude-bash-guard.sh;
  };

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
      # Persistently enable marketplace plugins (e.g. `laurel-eng@Laurel`)
      # without `--plugin-dir`. Gated on non-empty so personal hosts emit no
      # `enabledPlugins` key at all (byte-identical settings.json).
      enabledPlugins = lib.mkIf (ccCfg.enabledPlugins != [ ]) (
        lib.genAttrs ccCfg.enabledPlugins (_: true)
      );

      # The company `laurel-eng` tooling installs an enterprise
      # managed-settings.json (model + OTEL telemetry) that sits ABOVE this
      # user settings.json in precedence. Deliberately leave `model` and the
      # OTEL `env` keys unset here so the two layers never silently fight.
      # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is user-scoped and not set by the
      # company layer, so it coexists without clobbering managed OTEL env.
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

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

      # `tui` is not in the public settings reference as of 2.1.x; kept as a
      # known-good internal key — verify via /config after major upgrades.
      tui = "fullscreen";

      # Documented control (Boolean, default true, min v2.1.119). Set explicitly
      # for intent. `autoCompactWindow` (undocumented; no tunable threshold
      # exists) and `autoDreamEnabled` (absent from docs) were removed.
      autoCompactEnabled = true;

      hooks = {
        # New turn starting — stamp working before any tool runs.
        UserPromptSubmit = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${notify.stateExe} claude working thinking";
                async = true;
              }
            ];
          }
        ];
        # Mechanical deny for irreversible / hook-bypassing bash commands. Not
        # async — a deny must resolve before the tool runs. A second catch-all
        # entry stamps per-pane working state with the tool + its input as the
        # reason (async, best-effort — never gates the tool).
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe bashGuardScript}";
              }
            ];
          }
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${notify.stateExe} claude working tool";
                async = true;
              }
            ];
          }
        ];
        # Tool returned — still working (back to thinking) until the next tool
        # or the turn ends.
        PostToolUse = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${notify.stateExe} claude working thinking";
                async = true;
              }
            ];
          }
        ];
        SessionEnd = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe worklogScript}";
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
                command = "${notify.exe} claude attention ${notify.focusExe}";
                async = true;
              }
              {
                type = "command";
                command = "${notify.stateExe} claude waiting message";
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
                command = "${notify.exe} claude done ${notify.focusExe}";
                async = true;
              }
              {
                type = "command";
                command = "${notify.stateExe} claude done \"your move\"";
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
