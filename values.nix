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

  llm = {
    withContext = {
      enable = true;
      vault = "Main";
      projectBasePath = "Projects";
    };
  };

  darwin = {
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
          "notion-calendar"
          "notion-mail"
          "orbstack"
          "steam"
        ];
      };
    };
  };
}
