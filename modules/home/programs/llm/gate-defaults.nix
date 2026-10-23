{ rulesFile, styleFile }:
let
  bulkRead = import ./bulk-read.nix;
  outputStyle = import ./lib/output-style.nix;

  prose = {
    style = styleFile;

    block_on = [ "Sysinit.CitationMarkup" ];

    inherit (outputStyle) shape reminder;

    session = ''
      IMPORTANT: context is the budget that runs out first. YOU MUST spend it on purpose.

        - Grep or Glob to find the lines. Read the range, not the file.
        - Delegate a search that spans many files to a subagent, which reads in its own
          window and reports back the conclusion.
        - Never re-read a file to confirm an edit that Edit or Write already reported.
    '';
  };
in
{
  chains = {
    UserPromptSubmit = [

      { provider = "edit-event"; }
      { provider = "notes"; }
      {
        provider = "prose-gate";
        args = {
          mode = "remind";
          inherit (prose) reminder;
        };
      }
      { provider = "review-gate"; }
    ];
    PreToolUse = [
      {
        provider = "bash-guard";
        match = "^Bash$";
        args.rules = rulesFile;

        args.reader = bulkRead.reader;
      }
      {
        provider = "nix-guard";
        match = "^(Edit|Write|NotebookEdit)$";
      }
      {
        provider = "read-router";
        match = "^Read$";
        args.trigger_kib = 16;
        args.reader = bulkRead.reader;
      }
      {
        provider = "review-gate";
        match = "^(Agent|Task)$";
      }
      {
        provider = "git-ai-gate";
        match = "^(functions\\.)?(Edit|Write|MultiEdit|NotebookEdit|apply_patch|Bash|exec_command|shell|shell_command)$";
        timeout = "10s";
      }
    ];
    PostToolUse = [

      {
        provider = "edit-event";
        match = "^(Edit|Write|MultiEdit|NotebookEdit|apply_patch)$";
      }
      {
        provider = "git-ai-gate";
        match = "^(functions\\.)?(Edit|Write|MultiEdit|NotebookEdit|apply_patch|Bash|exec_command|shell|shell_command)$";
        timeout = "10s";
      }
      {
        provider = "lint-gate";
        match = "^(Edit|Write|MultiEdit)$";
      }
      {
        provider = "prose-gate";
        match = "^(Agent|Task)$";
        args.mode = "report";
      }
      {
        provider = "review-gate";
        match = "^(Agent|Task)$";
      }
    ];
    SessionStart = [
      {
        provider = "prose-gate";
        args = {
          mode = "session";
          inherit (prose) session;
        };
      }
    ];
    SubagentStart = [ { provider = "review-gate"; } ];
    Stop = [
      { provider = "loop-gate"; }
      {
        provider = "prose-gate";
        args = {
          mode = "check";
          inherit (prose)
            style
            block_on
            shape
            ;
        };
      }
    ];
  };

  review = {
    tiers = {
      trivial = {
        max_lines = 10;
        max_files = 20;
        critics = 0;
      };
      lite = {
        max_lines = 100;
        max_files = 20;
        critics = 1;
      };
      full = {
        critics = 3;
      };
    };
    sensitive = [
      "**/secrets/**"
      "**/.github/workflows/**"
      "modules/darwin/system.nix"
      "modules/nixos/**"
      "hosts/**"
      "modules/home/programs/llm/harnesses/**"
      "modules/home/programs/llm/lib/allowlist.nix"
    ];
    readonly_agents = [
      "Explore"
      "review-mediator"
    ];
    passes_max = 2;
  };

  providerNames = [
    "bash-guard"
    "edit-event"
    "lint-gate"
    "loop-gate"
    "nix-guard"
    "notes"
    "prose-gate"
    "read-router"
    "review-gate"
  ];
}
