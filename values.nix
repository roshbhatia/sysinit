{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    userName = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    githubUser = "roshbhatia";
    credentialUsername = "roshbhatia";
  };

  darwin = {
    borders = {
      enable = false;
    };

    homebrew = {
      additionalPackages = {
        taps = [ ];
        brews = [ ];
        casks = [
          "betterdiscord-installer"
          "calibre"
          "discord"
          "notion"
          "steam"
        ];
      };
    };
  };

  yarn = {
    additionalPackages = [ ];
  };

  theme = {
    colorscheme = "catppuccin";
    variant = "macchiato";
    transparency = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
  };

  wezterm = {
    shell = "zsh";
  };

  llm = {
    goose = {
      provider = "claude-code";
    };
    claude = {
      enabled = true;
    };
  };
}
