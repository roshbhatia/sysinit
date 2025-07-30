# modules/home/configurations/utils/default.nix
# Purpose: Utility scripts organized by functional groups
# Provides custom scripts for development, networking, git, and system tasks

{ ... }:

{
  home.file = {
    # Network utilities
    ".local/bin/dns-flush" = {
      source = ./network/dns-flush;
      executable = true;
    };

    # Development utilities
    ".local/bin/fzf-preview" = {
      source = ./dev/fzf-preview;
      executable = true;
    };

    ".local/bin/gh-whoami" = {
      source = ./dev/gh-whoami;
      executable = true;
    };

    # Git utilities
    ".local/bin/git-ai-commit" = {
      source = ./git/git-ai-commit;
      executable = true;
    };

    # System utilities
    ".local/bin/loglib.sh" = {
      source = ./system/loglib.sh;
      executable = true;
    };
  };
}
