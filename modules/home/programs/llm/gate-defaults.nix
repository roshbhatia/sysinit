# The default gate chains and review policy, as a pure function, so the module
# and the flake check render the same document.
#
# Matchers are regular expressions over the harness's tool name. Claude Code
# names its shell tool `Bash`; codex mirrors those names. `Task` is the older
# name of the `Agent` tool and stays matched for a harness that still sends it.
{ rulesFile, styleFile }:
let
  bulkRead = import ./bulk-read.nix;

  # prose-gate is gate's mechanism and this is its content: which vale style,
  # which rule records on one hit, and every text it injects. The provider
  # holds none of it, so a wording change here is a switch and not a rebuild.
  prose = {
    style = styleFile;
    # A leaked tool fingerprint is one fault on the first hit; a second
    # occurrence adds no evidence.
    block_on = [ "Sysinit.CitationMarkup" ];
    # Closes the recorded findings: what to send instead.
    shape = ''
      Send the whole reply again in ASD-STE100, in this shape and nothing else:

        1. What changed, in one sentence per change.
        2. Why, only where the change is not self-explaining.
        3. The next concrete action.

      One instruction per sentence, active voice, one term per concept. Numbers, not
      adjectives. Keep a sentence under 25 words. Use a list or a table when it
      carries the answer better than a sentence.
    '';
    # Claude Code re-states a built-in output style on every turn from its
    # `turnReminder` and a custom style never, so `sysinit-ste` is stated once
    # at session start. This is that missing per-turn line, which is why it
    # names the style rather than only its rules.
    reminder = "The sysinit-ste output style is active. Follow it. Answer shape: what changed, why, next action. One sentence under 25 words per instruction. No em-dash, no preamble, no plan announcement, no closing summary. Keep an error, a failing test, or a destructive-action confirmation whole.";
    # The output style is already loaded at SessionStart, so restating it buys
    # nothing. These three rules are stated nowhere else, and a fresh or
    # compacted session has no other way to learn them. A fourth, bounding a
    # command that prints without limit, is bash-guard's rewrite now: a hook
    # that cannot be skipped beats a rule the model may skip.
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
      # edit-event saves the prompt, so the next write can name what asked
      # for it. First, because it answers pass and nothing may skip it.
      { provider = "edit-event"; }
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
        # bash-guard denies `cat` on a large file with the same sentence
        # read-router uses, so it needs the same reader or the two disagree.
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
    ];
    PostToolUse = [
      # The two recorders run first, so a later block never skips attribution:
      # the edit is already on disk. edit-event appends the edit log and commits
      # the file into the workspace's shadow repository under the saved prompt;
      # git-ai-gate checkpoints its lines to refs/notes/ai.
      {
        provider = "edit-event";
        match = "^(Edit|Write|MultiEdit|NotebookEdit|apply_patch)$";
      }
      {
        provider = "git-ai-gate";
        match = "^(Edit|Write|MultiEdit)$";
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

  # Cloudflare's tiering with this repository's permission surfaces marked
  # sensitive. The tier is the owner's decision, made once here.
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

  # gate's own providers, whose manifests ship in pkgs.gate-providers.
  providerNames = [
    "bash-guard"
    "edit-event"
    "lint-gate"
    "loop-gate"
    "nix-guard"
    "prose-gate"
    "read-router"
    "review-gate"
  ];
}
