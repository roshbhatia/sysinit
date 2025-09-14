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
      enable = true;
    };

    tailscale = {
      enable = true;
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
      provider = "openrouter";
      leadModel = "qwen/qwen3-coder:free";
      model = "google/gemini-2.0-flash-exp:free";
    };
    claude = {
      enabled = true;
    };
  };
}
