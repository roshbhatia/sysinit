_:

{
  home.file = {
    ".local/bin/dns-flush" = {
      source = ./network/dns-flush.nu;
      executable = true;
    };

    ".local/bin/fzf-preview" = {
      source = ./dev/fzf-preview.nu;
      executable = true;
    };

    ".local/bin/gh-auth-setup" = {
      source = ./dev/gh-auth-setup.nu;
      executable = true;
    };

    ".local/bin/gh-whoami" = {
      source = ./dev/gh-whoami.nu;
      executable = true;
    };

    ".local/bin/set-background" = {
      source = ./system/set-background.nu;
      executable = true;
    };

    ".local/bin/connect" = {
      source = ./dev/connect.nu;
      executable = true;
    };

    ".local/bin/loglib.nu" = {
      source = ./dev/loglib.nu;
      executable = true;
    };
  };
}
