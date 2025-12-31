# Skills configuration for OpenCode
# Each skill is a directory with SKILL.md (required) and optional supporting files
# Supporting files: docs (*.md), scripts (*.sh), examples (*.ts, *.js), etc.
#
# Structure:
# skills/
#   ├── skill-name/
#   │   ├── SKILL.md (required - metadata + instructions)
#   │   ├── supporting-doc.md (optional)
#   │   ├── script.sh (optional)
#   │   └── example.ts (optional)
#   └── default.nix (this file - orchestration)

{
  # Skill definitions with metadata
  # OpenCode uses these to list available skills and their descriptions
  metadata = {
    verification-before-completion = {
      name = "verification-before-completion";
      description = "Use when about to claim work is complete, fixed, or passing—requires running verification commands and confirming output before making any success claims. Evidence before assertions always.";
      files = [ "SKILL.md" ];
    };
    receiving-code-review = {
      name = "receiving-code-review";
      description = "Use when receiving code review feedback, before implementing suggestions—verify against codebase reality and evaluate technical soundness before implementing.";
      files = [ "SKILL.md" ];
    };
    executing-plans = {
      name = "executing-plans";
      description = "Use when you have a written implementation plan to execute in a separate session with review checkpoints.";
      files = [ "SKILL.md" ];
    };
    systematic-debugging = {
      name = "systematic-debugging";
      description = "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes.";
      files = [
        "SKILL.md"
        "root-cause-tracing.md"
        "defense-in-depth.md"
        "condition-based-waiting.md"
        "find-polluter.sh"
        "condition-based-waiting-example.ts"
      ];
    };
    using-git-worktrees = {
      name = "using-git-worktrees";
      description = "Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification.";
      files = [ "SKILL.md" ];
    };
    test-driven-development = {
      name = "test-driven-development";
      description = "Use when implementing any feature or bugfix, before writing implementation code.";
      files = [
        "SKILL.md"
        "testing-anti-patterns.md"
      ];
    };
    brainstorming = {
      name = "brainstorming";
      description = "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.";
      files = [ "SKILL.md" ];
    };
    using-superpowers = {
      name = "using-superpowers";
      description = "Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions.";
      files = [ "SKILL.md" ];
    };
  };
}
