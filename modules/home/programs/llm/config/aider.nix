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
      vim = true;
      notifications = true;
      # Honor pre-commit hooks (gpg signing, formatters) on aider commits.
      git-commit-verify = true;

      # Match the no-co-author posture of every other harness: aider defaults
      # both of these to true, which would stamp commits against repo policy.
      attribute-co-authored-by = false;
      attribute-author = false;
      # Drop an `# AI!` comment in any file to trigger aider without a prompt.
      watch-files = true;

      # Auto-accept all confirmations (equivalent to --yes).
      yes = true;

      # Architect/editor split: a stronger model plans, a cheaper model edits.
      # See https://aider.chat/docs/usage/modes.html#architect-mode-and-the-editor-model
      architect = true;
      auto-accept-architect = true;
      model = "anthropic/claude-sonnet-4-5";
      editor-model = "anthropic/claude-haiku-4-5";

      # Ollama local inference endpoint. Switch models with:
      #   aider --model ollama_chat/qwen2.5-coder:14b
      # No openai-api-key needed; Ollama ignores the value but aider requires
      # a non-empty string when openai-api-base is set.
      openai-api-base = "http://localhost:11434/v1";
      openai-api-key = "ollama";

      # Always-loaded convention file mirroring AGENTS.md.
      read = "${config.home.homeDirectory}/${conventionsPath}";
    };
  };

  home.file.${conventionsPath} = {
    text = kit.mkInstructions "~/.claude/skills";
    force = true;
  };
}
