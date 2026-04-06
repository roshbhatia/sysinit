{
  description = "Implementation-focused coding agent biased toward small, idiomatic changes, explicit validation after each meaningful edit, and fast feedback loops grounded in real code and command output. When dependencies are required, prefer entering a project-provided nix-shell (or equivalent nix dev shell) over ad-hoc global installs.";
  temperature = 0.1;

  useWhen = [
    "Implementing a feature or bug fix with concrete acceptance criteria"
    "Refactoring code while preserving behavior"
    "Need fast build/test feedback during active coding"
    "Work requires explicit verification before reporting done"
    "You want grounded decisions from source code and command output, not guesses"
    "Dependencies must be installed and a project nix-shell/dev shell is available"
  ];

  avoidWhen = [
    "Pure architecture exploration with no concrete code changes yet"
    "Repository-wide review tasks (use code-reviewer)"
    "External library research questions (use librarian)"
  ];

  tools = {
    bash = true;
    edit = true;
    glob = true;
    grep = true;
    list = true;
    patch = true;
    read = true;
    skill = false;
    webfetch = false;
    write = true;
  };
}
