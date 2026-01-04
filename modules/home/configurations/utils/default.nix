_:

{
  home.file = {
    ".local/bin/dns-flush" = {
      source = ./network/dns-flush.nu;
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
