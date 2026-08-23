{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # fx evaluates rules last-match-wins, and Nix serialises an attrset in key
  # order, so "*" (0x2A) is emitted before every letter and the specific rules
  # after it win. That is what makes the catch-all safe here.
  #
  # The keys are fx permission names, not tool names: write_file and edit_file
  # both resolve to "edit", and run_command resolves to "bash".
  fxPermission = {
    "*" = "ask";
    read = "allow";
    list = "allow";
    glob = "allow";
    grep = "allow";
    edit = "allow";
    skill = "allow";
    web_fetch = "allow";
    # An allow rule on bash matches only a command with no shell operator, so a
    # compound command falls through to review rather than running unchecked.
    # Deny keeps the generic wildcard match, so the destructive globs still bite.
    bash = {
      "*" = "allow";
    }
    // (llmLib.allowlist.formatDestructiveForOpencode llmLib.allowlist.destructiveDenyGlobs);
  };
in
{
  # fx rewrites settings.json whenever `fx provider` or `/model` runs, so this is
  # a managed file rather than a symlink. The model keys stay the user's to set
  # from the interactive shell; only the provider and the rules are reasserted.
  # The OAuth token lives in ~/.fx/chatgpt-auth.json, which Nix never touches.
  sysinit.llm.managedFiles.fx = {
    path = ".fx/settings.json";
    format = "json";
    content = {
      provider = "codex";
      permission_mode = "auto";
      permission = fxPermission;
    };
    enforce = [
      "provider"
      "permission"
    ];
  };

  home.file.".fx/AGENTS.md" = {
    text = kit.mkInstructionsWithStyle {
      harness = "fx";
      skillsRoot = "~/.claude/skills";
    };
    force = true;
  };
}
