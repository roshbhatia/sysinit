{ pkgs, ... }:
{
  programs.aider-chat = {
    enable = true;
    # Upstream nixpkgs 0.86.1 package has failing tests; skip them
    package = pkgs.aider-chat.overridePythonAttrs (_: { doCheck = false; });
    settings = {
      dark-mode = true;
      cache-prompts = true;
      dirty-commits = false;
      show-model-warnings = false;
      auto-accept-architect = false;
    };
  };
}
