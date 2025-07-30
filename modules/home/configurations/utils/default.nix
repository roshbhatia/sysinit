{ lib, ... }:
{
  home.file = {
    ".local/bin/dns-flush" = {
      source = ./dns-flush;
      executable = true;
    };

    ".local/bin/fzf-preview" = {
      source = ./fzf-preview;
      executable = true;
    };

    ".local/bin/git-ai-commit" = {
      source = ./git-ai-commit;
      executable = true;
    };

    ".local/bin/gh-whoami" = {
      source = ./gh-whoami;
      executable = true;
    };

    ".local/bin/loglib.sh" = {
      source = ./loglib.sh;
      executable = true;
    };
  };
}

