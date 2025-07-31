{ lib, ... }:

let
  litellm = import ../shared/litellm.nix;
in
{
  home.file.".aider.conf.yml" = {
    text = lib.generators.toYAML { } {
      show-model-warnings = false;
      openai-api-base = litellm.uri;
      model = litellm.model;
      editor-edit-format = "architect";
      restore-chat-history = true;
      cache-prompts = true;
      map-refresh = "auto";
      gitignore = false;
      auto-commits = false;
      dirty-commits = false;
      attribute-author = false;
      attribute-committer = false;
      attribute-commit-message-author = true;
      skip-sanity-check-repo = true;
    };
    force = true;
  };
}

