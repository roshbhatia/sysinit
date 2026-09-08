# The default gate chains and review policy, as a pure function, so the module
# and the flake check render the same document.
#
# Matchers are regular expressions over the harness's tool name. Claude Code
# names its shell tool `Bash`; codex mirrors those names. `Task` is the older
# name of the `Agent` tool and stays matched for a harness that still sends it.
{ rulesFile }:
let
  bulkRead = import ./bulk-read.nix;
in
{
  chains = {
    UserPromptSubmit = [
      {
        provider = "prose-gate";
        args.mode = "remind";
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
        args.mode = "session";
      }
    ];
    SubagentStart = [ { provider = "review-gate"; } ];
    Stop = [
      { provider = "loop-gate"; }
      {
        provider = "prose-gate";
        args.mode = "check";
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
    "lint-gate"
    "loop-gate"
    "nix-guard"
    "read-router"
    "review-gate"
  ];
}
