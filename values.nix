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

  theme = {
    colorscheme = "rose-pine";
    variant = "moon";
    appearance = "dark";
    font = {
      monospace = "TX-02";
      nerdfontFallback = "Wumpus Mono";
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
