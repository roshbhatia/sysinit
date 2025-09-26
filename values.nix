{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  darwin = {
    tailscale = {
      enable = true;
    };

    homebrew = {
      additionalPackages = {
        taps = [
          "qmk/qmk"
        ];
        brews = [
          "qmk"
        ];
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
      model = "qwen/qwen3-coder:free";
    };
  };
}
