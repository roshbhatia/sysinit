{ ... }:

{
  home.file = {

    ".local/bin/dns-flush" = {
      source = ./network/dns-flush;
      executable = true;
    };

    ".local/bin/fzf-preview" = {
      source = ./dev/fzf-preview;
      executable = true;
    };

    ".local/bin/gh-whoami" = {
      source = ./dev/gh-whoami;
      executable = true;
    };

    ".local/bin/git-ai-commit" = {
      source = ./git/git-ai-commit;
      executable = true;
    };

    ".local/bin/loglib.sh" = {
      source = ./system/loglib.sh;
      executable = true;
    };
  };
}
