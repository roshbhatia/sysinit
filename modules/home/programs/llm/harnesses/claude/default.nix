{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";

  defaultInstructions = kit.mkInstructions {
    harness = "claude";
    skillsRoot = "~/.claude/skills";
  };

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
      exec uv run --script ${./worklog-hook.py}
    '';
  };

  # PreToolUse(Bash) guard: the mechanical floor under the global CLAUDE.md
  # prohibitions (no force-push, no --no-verify/--no-gpg-sign, no reset --hard,
  # no clean -f, no branch -D). `auto` permission mode is deliberately NOT used —
  # its built-in block list also blocks push-to-main, which this repo permits.
  # Best-effort / fail-open: bashOptions cleared so a non-zero grep never becomes
  # a hook abort (Claude treats exit 2 as a block).
  bashGuardScript = llmLib.guards.mkBashGuard {
    inherit pkgs;
    name = "claude-bash-guard";
  };

  # Same contract as the bash guard, applied to file-writing tools: denies edits
  # whose target resolves into /nix/store, so a Nix-managed dotfile sends the
  # agent to the generating module instead of a read-only store path.
  nixGuardScript = pkgs.writeShellApplication {
    name = "claude-nix-guard";
    runtimeInputs = [ pkgs.jq ];
    bashOptions = [ ];
    text = builtins.readFile ./nix-guard.sh;
  };

  # PreToolUse guard for the Slack send tools. `dangerouslySkipPermissions`
  # bypasses `permissions.ask`, so the hook is the only gate still active.
  # slack_send_message and slack_send_message_draft are allowed when the
  # destination channel_id is in sysinit.llm.mcp.slackAllowedSendChannels
  # (set by skill-aware consumers such as sysinit.laurel). All other destinations
  # and all slack_schedule_message calls are denied. Fail-open (bashOptions
  # cleared) so an extraction miss never becomes a hook abort.
  slackGuardScript =
    let
      # Generates: "id1"|"id2"|... for a shell case pattern.
      mkChanPat = channels: lib.concatStringsSep "|" (map (c: "\"${c}\"") channels);
      # Send tools that support per-channel gating (exclude schedule).
      sendNowTools = lib.filter (
        t: !(lib.hasSuffix "schedule_message" t)
      ) llmLib.allowlist.slackSendTools;
      scheduleTools = lib.filter (lib.hasSuffix "schedule_message") llmLib.allowlist.slackSendTools;
      # Inline case arm that allows approved channels; empty when no channels set.
      allowedChanBlock =
        if slackAllowedChannels != [ ] then
          ''
            case "$_channel" in
              ${mkChanPat slackAllowedChannels})
                exit 0
                ;;
            esac
          ''
        else
          "";
    in
    pkgs.writeShellApplication {
      name = "claude-slack-guard";
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = ''
        input="$(cat)"
        tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
        case "$tool" in
          ${lib.concatStringsSep " | " (map (t: "\"${t}\"") sendNowTools)})
            _channel="$(printf '%s' "$input" | jq -r '.tool_input.channel_id // empty' 2>/dev/null)"
            ${allowedChanBlock}jq -n '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: "Slack sends are gated to skill-approved channels. This destination is not in the allow-list."
              }
            }'
            ;;
          ${lib.concatStringsSep " | " (map (t: "\"${t}\"") scheduleTools)})
            jq -n '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: "Scheduled Slack sends are always blocked."
              }
            }'
            ;;
        esac
        exit 0
      '';
    };

  slackToolMatcher = lib.concatStringsSep "|" llmLib.allowlist.slackSendTools;

  # STE output style: Claude Code's native outputStyle layer. Rules are
  # defined once in instructions.nix (outputStyleRules) and wrapped here with
  # the Claude-specific file frontmatter. Other harnesses consume the same rules
  # via makeInstructionsWithStyle (no frontmatter, appended at recency position).
  steOutputStyle = ''
    ---
    name: sysinit-ste
    description: Simplified Technical English, ADHD-shaped output
    ---

    ${kit.llmLib.instructions.outputStyleRules}
  '';

  subagents = kit.llmLib.instructions.subagentDefs;

  disabledBuiltinServers = config.sysinit.llm.mcp.disabledBuiltinServers;
  slackAllowedChannels = config.sysinit.llm.mcp.slackAllowedSendChannels;
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      # No CLAUDE_CODE_SHELL. It pinned zsh, and the owner hit problems from it:
      # the harness then runs every tool call through an interactive-shell profile
      # whose prompt, completion, and plugin output contaminates captured stdout.
      # Unset, the harness uses the system default shell.
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        # Nix owns updates for every harness in this repo; disable the in-place
        # auto-updater so it never fights the flake pin.
        DISABLE_AUTOUPDATER = "1";
      };

      # How a teammate runs WHEN one is used, not whether to use one. Pinned so
      # a teammate never falls back to tmux/iTerm split panes.
      #
      # Adversarial-review critics deliberately do NOT take this path: they run
      # as fresh-context subagents, because a critic that shares the author's
      # context inherits the author's reasoning and stops being adversarial. The
      # `adversarial-review` skill routes on that, not on AGENT_TEAMS.
      teammateMode = "in-process";

      dangerouslySkipPermissions = true;

      sandbox = {
        enabled = false;
      };

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

      # Suppress "N servers need authentication" for unused claude.ai integrations.
      # The home.activation below writes the same list to ~/.claude.json, which is
      # the authoritative location per github.com/anthropics/claude-code/issues/66737.
      disabledMcpServers = disabledBuiltinServers;

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
          {
            matcher = "Edit|Write|NotebookEdit";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe nixGuardScript}";
              }
            ];
          }
          # Channel-gated Slack send guard. Allows slack_send_message and
          # slack_send_message_draft to skill-approved channel_ids; denies
          # all other destinations and all slack_schedule_message calls.
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
              # Evaluates a declared STOP condition before the turn is allowed to
              # end. Not async: a block must resolve before control returns.
              # Disarmed unless `loop-gate arm` wrote state for this directory,
              # so an ordinary turn pays one file-existence check.
              {
                type = "command";
                command = "${profileBin}/loop-gate check";
              }
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
        harness = "claude";
      }
    ) subagents;
  };

  # Custom output style selected via settings.outputStyle above. Claude Code
  # reads styles from ~/.claude/output-styles/<name>.md.
  home.file.".claude/output-styles/sysinit-ste.md" = {
    text = steOutputStyle;
    force = true;
  };

  # ~/.claude.json is the authoritative location for disabledMcpServers, per
  # github.com/anthropics/claude-code/issues/66737; settings.json above is a
  # secondary path. Claude Code owns the rest of this file outright, including
  # all session state, so Nix declares exactly the one key and the three-way
  # merge preserves everything else.
  sysinit.llm.managedFiles.claude-json = {
    # Claude Code writes disabledMcpServers itself when a server is toggled off
    # in /mcp. Declaring an empty list here would enforce that empty list over
    # the owner's own choices, so this file is managed only when this
    # repository actually has an opinion.
    enable = disabledBuiltinServers != [ ];
    path = ".claude.json";
    format = "json";
    content.disabledMcpServers = disabledBuiltinServers;
    # This repository owns the list outright, so it is reasserted rather than
    # merged. It is a list, and a merge compares a list whole: without this,
    # Claude Code adding one entry from /mcp would make the next edit here an
    # unresolvable conflict on a 117KB file of live session state.
    enforce = [ "disabledMcpServers" ];
    # Everything else in this file is Claude Code's own state. Creating it on a
    # machine where Claude Code has never run would fabricate that state.
    createIfMissing = false;
  };
}
