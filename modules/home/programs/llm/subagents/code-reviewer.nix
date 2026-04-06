{
  description = "Code review agent that checks changes against project conventions, flags issues with file:line references, and reports CRITICAL/WARNING/GOOD findings. If validation setup requires dependencies, prefer project-provided nix-shell/nix develop environments over global installs.";
  temperature = 0.1;

  useWhen = [
    "Before opening a PR"
    "After completing a feature or fix"
    "When unsure if changes follow project conventions"
    "Checking for security issues in new code"
    "Validating changes against CLAUDE.md rules"
  ];

  avoidWhen = [
    "Mid-implementation (wait until changes are complete)"
    "Reviewing unchanged files"
    "Style-only questions (ask directly)"
  ];

  tools = {
    bash = false;
    edit = false;
    glob = true;
    grep = true;
    list = true;
    patch = false;
    read = true;
    skill = false;
    webfetch = false;
    write = false;
  };
}
