{ pkgs, ... }:
{
  # Config managed by sysinit.agents; binary and env vars only here.
  home.sessionVariables = {
    CONTEXT_FILE_NAMES = builtins.toJSON [
      "AGENTS.md"
      ".goosehints"
      ".cursorrules"
      "CLAUDE.md"
      "CONSTITUTION.md"
      "CONTRIBUTING.md"
      "COPILOT.md"
    ];
  };

  home.packages = [ pkgs.goose-cli ];
}
