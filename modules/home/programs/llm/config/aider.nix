{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Aider's `--read FILE` flag (or `read:` in config) lets us preload a
  # convention file every session. We render the same content AGENTS.md
  # produces (from instructions.nix) into ~/.aider/CONVENTIONS.md so aider
  # sees the same canonical guidance every other harness reads.
  conventionsPath = ".aider/CONVENTIONS.md";
in
{
  programs.aider-chat = {
    enable = true;
    # Upstream nixpkgs 0.86.1 package has failing tests; skip them
    package = pkgs.aider-chat.overridePythonAttrs (_: {
      doCheck = false;
    });
    settings = {
      dark-mode = true;
      cache-prompts = true;
      dirty-commits = false;
      show-model-warnings = false;

      # Architect/editor split: a stronger model plans, a cheaper model edits.
      # See https://aider.chat/docs/usage/modes.html#architect-mode-and-the-editor-model
      architect = true;
      auto-accept-architect = false;
      model = "anthropic/claude-sonnet-4-5";
      editor-model = "anthropic/claude-haiku-4-5";

      # Always-loaded convention file mirroring AGENTS.md.
      read = "${config.home.homeDirectory}/${conventionsPath}";
    };
  };

  home.file.${conventionsPath} = {
    text = kit.mkInstructions "~/.claude/skills";
    force = true;
  };
}
