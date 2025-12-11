_:

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

    ".local/bin/gh-auth-setup" = {
      source = ./dev/gh-auth-setup;
      executable = true;
    };

    ".local/bin/gh-whoami" = {
      source = ./dev/gh-whoami;
      executable = true;
    };

    ".local/bin/vimdiff" = {
      source = ./dev/vimdiff;
      executable = true;
    };

    ".local/bin/loglib.sh" = {
      source = ./system/loglib.sh;
      executable = true;
    };
  };
}
