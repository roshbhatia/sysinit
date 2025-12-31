{
  verificationBeforeCompletion = builtins.readFile ./verification-before-completion.nix;
  receivingCodeReview = builtins.readFile ./receiving-code-review.nix;
  executingPlans = builtins.readFile ./executing-plans.nix;
  systematicDebugging = builtins.readFile ./systematic-debugging.nix;
  usingGitWorktrees = builtins.readFile ./using-git-worktrees.nix;
  testDrivenDevelopment = builtins.readFile ./test-driven-development.nix;
  brainstorming = builtins.readFile ./brainstorming.nix;
  usingSuperpowers = builtins.readFile ./using-superpowers.nix;
}
