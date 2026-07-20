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

  # PreToolUse guard for the Slack send tools. `dangerouslySkipPermissions`
  # bypasses `permissions.ask`, so the old ask-tier gate was inert — a hook is
  # the only mechanism that still runs under skip. This denies the three
  # slack_send_* MCP tools and tells the agent to have the human send. Fail-open
  # (bashOptions cleared) so an extraction miss never becomes a hook abort. The
  # deny set is the Nix-managed slackSendTools list, kept in sync with the
  # matcher below.
  slackGuardScript = pkgs.writeShellApplication {
    name = "claude-slack-guard";
    runtimeInputs = [ pkgs.jq ];
    bashOptions = [ ];
    text = ''
      input="$(cat)"
      tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
      case "$tool" in
        ${lib.concatStringsSep " | " (map (t: "\"${t}\"") llmLib.allowlist.slackSendTools)})
          jq -n '{
            hookSpecificOutput: {
              hookEventName: "PreToolUse",
              permissionDecision: "deny",
              permissionDecisionReason: "Slack sends are gated: ask the human to send this message. dangerouslySkipPermissions makes the ask-tier inert, so this is enforced mechanically."
            }
          }'
          ;;
      esac
      exit 0
    '';
  };

  slackToolMatcher = lib.concatStringsSep "|" llmLib.allowlist.slackSendTools;

  # STE output style: encodes the shared Communication rules as a first-class
  # system-prompt layer instead of relying only on the context-file text.
  steOutputStyle = ''
    ---
    name: sysinit-ste
    description: Simplified Technical English, ADHD-shaped output
    ---

    Write all output in Simplified Technical English (ASD-STE100).

    - Use one instruction per sentence. Keep procedure sentences to 20 words or
      fewer and descriptive sentences to 25 or fewer. Keep paragraphs to 6
      sentences or fewer.
    - Use active voice and simple present, past, future, or imperative verbs.
      Avoid gerund chains and stacked auxiliaries.
    - One word, one meaning: pick a single term for a concept and reuse it. Do
      not vary the term for style.
    - Use only terms established in this repo, its skills, or the standard
      vocabulary of the tool at hand. Do not invent metaphors, idioms, or coined
      phrases.
    - Shape output so a reader with ADHD can act on it: lead with the action or
      answer; number multi-step work; end with the next concrete action; restate
      the current state each turn; give concrete size or time estimates; make
      completed work visible; state errors matter-of-factly; cap lists at 5 items.
    - No preamble, recap, or pleasantries.
    - Break these rules only when the user asks you to explain or walk through, you
      must confirm a destructive action, you name the wrong assumption in a debug
      spiral, or the request has real ambiguity.
  '';

  subagents = kit.llmLib.instructions.subagentDefs;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        # Nix owns updates for every harness in this repo; disable the in-place
        # auto-updater so it never fights the flake pin.
        DISABLE_AUTOUPDATER = "1";
      };

      dangerouslySkipPermissions = true;

      # `ask` is intentionally absent: dangerouslySkipPermissions bypasses it, so
      # the Slack send gate lives in the slackGuardScript PreToolUse hook below.
      # The `allow` tiers are kept as intent documentation (inert under skip,
      # load-bearing if skip is ever dropped).
      permissions = {
        allow =
          llmLib.allowlist.formatForClaude llmLib.allowlist.tierA
          ++ llmLib.allowlist.formatForClaude llmLib.allowlist.tierB
          ++ llmLib.allowlist.tierMcp;
      };

      # Snapshot files before Write/Edit so /rewind can restore them.
      fileCheckpointingEnabled = true;
      # Persist reasoning effort for spec-driven work instead of per session.
      effortLevel = "high";
      # Auto-failover when the primary model is overloaded.
      fallbackModel = [ "claude-sonnet-5" ];
      # Extended thinking on by default.
      alwaysThinkingEnabled = true;
      # Cross-session auto-memory (MEMORY.md) — set explicitly for intent.
      autoMemoryEnabled = true;
      # STE output style shipped via home.file below.
      outputStyle = "sysinit-ste";

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
        # New turn starting — stamp working and record the turn-start timestamp
        # (agent-notify reads it to gate done-notifications on elapsed time).
        UserPromptSubmit = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state claude working submit";
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
          # Mechanical Slack send gate (replaces the inert permissions.ask under
          # dangerouslySkipPermissions). Matcher targets exactly the three
          # slack_send_* tools; the script re-checks tool_name and denies.
          {
            matcher = slackToolMatcher;
            hooks = [
              {
                type = "command";
                command = "${lib.getExe slackGuardScript}";
              }
            ];
          }
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-state claude working tool";
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
              # Terminal transition: drop this pane's cross-surface bus entry.
              # Best-effort — readers also prune orphaned files by liveness.
              {
                type = "command";
                command = "${profileBin}/agent-state claude exit";
                async = true;
              }
            ];
          }
        ];
        # Informational notifications (dangerouslySkipPermissions skips all approvals
        # so Notification never fires for tool consent). Only fire the desktop alert;
        # do NOT set waiting state — the agent is still working, not blocked.
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-prompt claude attention ${profileBin}/agent-focus";
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
                command = "${profileBin}/agent-notify claude done ${profileBin}/agent-focus";
                async = true;
              }
              {
                type = "command";
                command = "${profileBin}/agent-state claude done \"your move\"";
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

  # Custom output style selected via settings.outputStyle above. Claude Code
  # reads styles from ~/.claude/output-styles/<name>.md.
  home.file.".claude/output-styles/sysinit-ste.md" = {
    text = steOutputStyle;
    force = true;
  };
}
