{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  darwin = {
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
