{ ... }:
{
  home.file.".aider.conf.yml" = {
    text = ''
      show-model-warnings: false

      openai-api-base: https://api.githubcopilot.com

      model: openai/gpt-4o
      editor-model: openai/gpt-4o
      editor-edit-format: architect
      weak-model: openai/gpt-3.5-turbo

      restore-chat-history: true
      cache-prompts: true
      map-refresh: auto

      gitignore: false

      auto-commits: false
      dirty-commits: false
      attribute-author: false
      attribute-committer: false
      attribute-commit-message-author: true

      skip-sanity-check-repo: true
    '';
    force = true;
  };
}
